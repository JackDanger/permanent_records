# frozen_string_literal: true

# PermanentRecords works with ActiveRecord to set deleted_at columns with a
# timestamp reflecting when a record was 'deleted' instead of actually deleting
# the record. All dependent records and associations are treated exactly as
# you'd expect: If there's a deleted_at column then the record is preserved,
# otherwise it's deleted.
module PermanentRecords
  # This module defines the public api that you can
  # use in your model instances.
  #
  # * is_permanent? #=> true/false, depending if you have a deleted_at column
  # * deleted?      #=> true/false, depending if you've called .destroy
  # * destroy       #=> sets deleted_at, your record is now in
  #                     the .destroyed scope
  # * revive        #=> undo the destroy
  module ActiveRecord # rubocop:disable Metrics/ModuleLength
    def self.included(base)
      base.extend Scopes
      base.extend IsPermanent

      base.instance_eval do
        define_model_callbacks :revive
      end
    end

    def is_permanent? # rubocop:disable Naming/PredicateName
      respond_to?(:deleted_at)
    end

    def deleted?
      if is_permanent?
        !!deleted_at
      else
        destroyed?
      end
    end

    def revive(options = nil)
      with_transaction_returning_status do
        if PermanentRecords.should_revive_parent_first?(options)
          revival.reverse
        else
          revival
        end.each { |p| p.call(options) }

        self
      end
    end

    def destroy(force = nil)
      with_transaction_returning_status do
        if !is_permanent? || PermanentRecords.should_force_destroy?(force)
          permanently_delete_records_after { super() }
        else
          destroy_with_permanent_records(force)
        end
      end
    end

    private

    def revival # rubocop:disable Metrics/MethodLength
      [
        lambda do |validate|
          revive_destroyed_dependent_records(validate)
        end,
        lambda do |validate|
          run_callbacks(:revive) do
            set_deleted_at(nil, validate)
            # increment all associated counters for counter cache
            each_counter_cache do |assoc_class, counter_cache_column, assoc_id|
              assoc_class.increment_counter(counter_cache_column, assoc_id)
            end
            true
          end
        end
      ]
    end

    def get_deleted_record # rubocop:disable Naming/AccessorMethodName
      self.class.unscoped.find(id)
    end

    # rubocop:disable Metrics/MethodLength
    def set_deleted_at(value, force = nil)
      return self unless is_permanent?

      record = get_deleted_record
      record.deleted_at = value
      begin
        # we call save! instead of update_attribute so an
        # ActiveRecord::RecordInvalid error will be raised if the record isn't
        # valid. (This prevents reviving records that disregard validation
        # constraints,)
        if PermanentRecords.should_ignore_validations?(force)
          record.save(validate: false)
        else
          record.save!
        end

        @attributes = record.instance_variable_get(:@attributes)
      rescue StandardError => e
        # trigger dependent record destruction (they were revived before this
        # record, which cannot be revived due to validations)
        record.destroy
        raise e
      end
    end

    # rubocop:enable Metrics/MethodLength

    def each_counter_cache
      _reflections.each do |name, reflection|
        association = respond_to?(name.to_sym) ? send(name.to_sym) : nil
        next if association.nil?
        next unless reflection.belongs_to? && reflection.counter_cache_column

        associated_class = association.class

        yield(associated_class, reflection.counter_cache_column, send(reflection.foreign_key))
      end
    end

    # rubocop:disable Metrics/MethodLength
    def destroy_with_permanent_records(force = nil)
      run_callbacks(:destroy) do
        if deleted? || new_record?
          save
        else
          set_deleted_at(Time.now, force)
          # decrement all associated counters for counter cache
          each_counter_cache do |assoc_class, counter_cache_column, assoc_id|
            assoc_class.decrement_counter(counter_cache_column, assoc_id)
          end
        end
        true
      end
      deleted? ? self : false
    end
    # rubocop:enable Metrics/MethodLength

    def add_record_window(_request, name, reflection)
      send(name).unscope(where: :deleted_at).where(
        [
          "#{reflection.klass.quoted_table_name}.deleted_at > ? " \
          'AND ' \
          "#{reflection.klass.quoted_table_name}.deleted_at < ?",
          deleted_at - PermanentRecords.dependent_record_window,
          deleted_at + PermanentRecords.dependent_record_window
        ]
      )
    end

    # TODO: Feel free to refactor this without polluting the ActiveRecord namespace.
    def revive_destroyed_dependent_records(force = nil)
      destroyed_dependent_relations.each do |relation|
        relation.to_a.each { |destroyed_dependent_record| destroyed_dependent_record.try(:revive, force) }
      end
      reload
    end

    # rubocop:disable Metrics/MethodLength
    def destroyed_dependent_relations
      PermanentRecords.dependent_permanent_reflections(self.class).map do |name, relation|
        case relation.macro.to_sym
        when :has_many
          if deleted_at
            add_record_window(send(name), name, relation)
          else
            send(name).unscope(where: :deleted_at)
          end
        when :has_one, :belongs_to
          self.class.unscoped { Array(send(name)) }
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def attempt_notifying_observers(callback)
      notify_observers(callback)
    rescue NoMethodError
      # do nothing: this model isn't being observed
    end

    # return the records corresponding to an association with the `:dependent
    # => :destroy` option
    def dependent_record_ids
      # check which dependent records are to be destroyed
      PermanentRecords.dependent_reflections(self.class)
                      .reduce({}) do |records, (key, _)|
        found = Array(send(key)).compact
        next records if found.empty?

        records.update found.first.class => found.map(&:id)
      end
    end

    # If we force the destruction of the record, we will need to force the
    # destruction of dependent records if the user specified `:dependent =>
    # :destroy` in the model.  By default, the call to
    # super/destroy_with_permanent_records (i.e. the &block param) will only
    # soft delete the dependent records; we keep track of the dependent records
    # that have `:dependent => :destroy` and call destroy(force) on them after
    # the call to super
    def permanently_delete_records_after(&_block)
      dependent_records = dependent_record_ids
      result = yield
      permanently_delete_records(dependent_records) if result
      result
    end

    # permanently delete the records (i.e. remove from database)
    def permanently_delete_records(dependent_records)
      dependent_records.each do |klass, ids|
        ids.each do |id|
          record = klass.unscoped.where(klass.primary_key => id).first
          next unless record

          record.deleted_at = nil if record.respond_to?(:deleted_at)
          record.destroy(:force)
        end
      end
    end
  end

  # ActiveRelation scopes
  module Scopes
    def deleted
      where arel_table[:deleted_at].not_eq(nil)
    end

    def not_deleted
      where arel_table[:deleted_at].eq(nil)
    end
  end

  # Included into ActiveRecord for all models
  module IsPermanent
    def is_permanent? # rubocop:disable Naming/PredicateName
      columns.detect { |c| c.name == 'deleted_at' }
    end
  end

  def self.should_force_destroy?(force)
    if force.is_a?(Hash)
      force[:force]
    else
      force == :force
    end
  end

  def self.should_revive_parent_first?(order)
    order.is_a?(Hash) && order[:reverse] == true
  end

  def self.should_ignore_validations?(force)
    force.is_a?(Hash) && force[:validate] == false
  end

  def self.dependent_record_window
    @dependent_record_window || 3.seconds
  end

  def self.dependent_record_window=(time_value)
    @dependent_record_window = time_value
  end

  def self.dependent_reflections(klass)
    klass.reflections.select do |_, reflection|
      # skip if there are no dependent record instances
      reflection.options[:dependent] == :destroy
    end
  end

  def self.dependent_permanent_reflections(klass)
    dependent_reflections(klass).select do |_name, reflection|
      reflection.klass.is_permanent?
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include PermanentRecords::ActiveRecord
  require 'permanent_records/active_record'
end
