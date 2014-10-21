module PermanentRecords

  # This module defines the public api that you can
  # use in your model instances.
  #
  # * is_permanent? #=> true/false, depending if you have a deleted_at column
  # * deleted?      #=> true/false, depending if you've called .destroy
  # * destroy       #=> sets deleted_at, your record is now in the .destroyed scope
  # * revive        #=> undo the destroy
  module ActiveRecord
    def self.included(base)

      base.extend Scopes
      base.extend IsPermanent

      base.instance_eval do
        define_model_callbacks :revive

        before_revive :revive_destroyed_dependent_records
      end
    end

    def is_permanent?
      respond_to?(:deleted_at)
    end

    def deleted?
      if is_permanent?
        !!deleted_at
      else
        destroyed?
      end
    end

    def revive(validate = nil)
      run_callbacks(:revive) { set_deleted_at(nil, validate) }
      self
    end

    def destroy(force = nil)
      if !is_permanent? || PermanentRecords.should_force_destroy?(force)
        return permanently_delete_records_after { super() }
      end
      destroy_with_permanent_records force
    end

    private

    def set_deleted_at(value, force = nil)
      return self unless is_permanent?
      record = self.class.unscoped.find(id)
      record.deleted_at = value
      begin
        # we call save! instead of update_attribute so an ActiveRecord::RecordInvalid
        # error will be raised if the record isn't valid. (This prevents reviving records that
        # disregard validation constraints,)
        if PermanentRecords.should_ignore_validations?(force)
          record.save(:validate => false)
        else
          record.save!
        end
        @attributes, @attributes_cache = record.attributes, record.attributes
        # workaround for active_record >= 3.2.0: re-wrap values of serialized attributes
        # (record.attributes returns the plain values but in the instance variables they are expected to be wrapped)
        if defined?(::ActiveRecord::AttributeMethods::Serialization::Attribute)
          serialized_attribute_class = ::ActiveRecord::AttributeMethods::Serialization::Attribute
          self.class.serialized_attributes.each do |key, coder|
            if @attributes.key?(key)
              attr = serialized_attribute_class.new(coder, @attributes[key], :unserialized)
              @attributes[key] = attr
              @attributes_cache[key] = attr
            end
          end
        end
      rescue Exception => e
        # trigger dependent record destruction (they were revived before this record,
        # which cannot be revived due to validations)
        record.destroy
        raise e
      end
    end

    def destroy_with_permanent_records(force = nil)
      run_callbacks(:destroy) do
        deleted? || new_record? ? save : set_deleted_at(Time.now, force)
      end
      self
    end

    def revive_destroyed_dependent_records
      self.class.reflections.select do |name, reflection|
        'destroy' == reflection.options[:dependent].to_s && reflection.klass.is_permanent?
      end.each do |name, reflection|
        cardinality = reflection.macro.to_s.gsub('has_', '')
        if cardinality == 'many'
          records = send(name).unscoped.where(
            [
              "#{reflection.quoted_table_name}.deleted_at > ?" +
              " AND " +
              "#{reflection.quoted_table_name}.deleted_at < ?",
              deleted_at - PermanentRecords.dependent_record_window,
              deleted_at + PermanentRecords.dependent_record_window
            ]
          )
        elsif cardinality == 'one' or cardinality == 'belongs_to'
          self.class.unscoped do
            records = [] << send(name)
          end
        end
        [records].flatten.compact.each do |dependent|
          dependent.revive
        end

        # and update the reflection cache
        send(name, :reload)
      end
    end

    def attempt_notifying_observers(callback)
      begin
        notify_observers(callback)
      rescue NoMethodError => e
        # do nothing: this model isn't being observed
      end
    end

    # return the records corresponding to an association with the `:dependent => :destroy` option
    def get_dependent_records
      dependent_records = {}

      # check which dependent records are to be destroyed
      klass = self.class
      klass.reflections.each do |key, reflection|
        if reflection.options[:dependent] == :destroy
          next unless records = self.send(key) # skip if there are no dependent record instances
          if records.respond_to? :size
            next unless records.size > 0 # skip if there are no dependent record instances
          else
            records = [] << records
          end
          dependent_record = records.first
          next if dependent_record.nil?
          dependent_records[dependent_record.class] = records.map(&:id)
        end
      end
      dependent_records
    end

    # If we force the destruction of the record, we will need to force the destruction of dependent records if the
    # user specified `:dependent => :destroy` in the model.
    # By default, the call to super/destroy_with_permanent_records (i.e. the &block param) will only soft delete
    # the dependent records; we keep track of the dependent records
    # that have `:dependent => :destroy` and call destroy(force) on them after the call to super
    def permanently_delete_records_after(&block)
      dependent_records = get_dependent_records
      result = block.call
      if result
        permanently_delete_records(dependent_records)
      end
      result
    end

    # permanently delete the records (i.e. remove from database)
    def permanently_delete_records(dependent_records)
      dependent_records.each do |klass, ids|
        ids.each do |id|
          record = begin
            klass.unscoped.find id
          rescue ::ActiveRecord::RecordNotFound
            next # the record has already been deleted, possibly due to another association with `:dependent => :destroy`
          end
          record.deleted_at = nil
          record.destroy(:force)
        end
      end
    end
  end

  module Scopes
    def deleted
      where arel_table[:deleted_at].not_eq(nil)
    end

    def not_deleted
      where arel_table[:deleted_at].eq(nil)
    end
  end

  module IsPermanent
    def is_permanent?
      columns.detect {|c| 'deleted_at' == c.name}
    end
  end

  def self.should_force_destroy?(force)
    if Hash === force
      force[:force]
    else
      :force == force
    end
  end

  def self.should_ignore_validations?(force)
    Hash === force && false == force[:validate]
  end

  def self.dependent_record_window
    @dependent_record_window || 3.seconds
  end

  def self.dependent_record_window=(time_value)
    @dependent_record_window = time_value
  end
end

ActiveRecord::Base.send :include, PermanentRecords::ActiveRecord

