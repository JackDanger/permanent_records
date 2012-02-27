module PermanentRecords
  def self.included(base)

    base.send :include, InstanceMethods

    # Rails 3
    if ActiveRecord::VERSION::MAJOR >= 3
      base.extend Scopes
      base.instance_eval { define_model_callbacks :revive }
    # Rails 2.x.x
    elsif base.respond_to?(:named_scope)
      base.named_scope :deleted, :conditions => 'deleted_at IS NOT NULL'
      base.named_scope :not_deleted, :conditions => { :deleted_at => nil }
      base.instance_eval { define_callbacks :before_revive, :after_revive }
      base.send :alias_method_chain, :destroy, :permanent_records
    # Early Rails code
    else
      base.extend EarlyRails
      base.instance_eval { define_callbacks :before_revive, :after_revive }
    end
    base.instance_eval do
      before_revive :revive_destroyed_dependent_records
      def is_permanent?
        columns.detect {|c| 'deleted_at' == c.name}
      end
    end
  end
  
  module Scopes
    def deleted
      where("#{table_name}.deleted_at IS NOT NULL")
    end
    def not_deleted
      where("#{table_name}.deleted_at IS NULL")
    end
  end
  
  module EarlyRails
    def with_deleted
      with_scope :find => {:conditions => "#{quoted_table_name}.deleted_at IS NOT NULL"} do
        yield
      end
    end
    
    def with_not_deleted
      with_scope :find => {:conditions => "#{quoted_table_name}.deleted_at IS NULL"} do
        yield
      end
    end
    
    # this next bit is basically stolen from the scope_out plugin
    [:deleted, :not_deleted].each do |name|
      define_method "find_#{name}" do |*args|
        send("with_#{name}") { find(*args) }
      end

      define_method "count_#{name}" do |*args|
        send("with_#{name}") { count(*args) }
      end

      define_method "calculate_#{name}" do |*args|
        send("with_#{name}") { calculate(*args) }
      end

      define_method "find_all_#{name}" do |*args|
        send("with_#{name}") { find(:all, *args) }
      end
    end
  end

  module InstanceMethods
    
    def is_permanent?
      respond_to?(:deleted_at)
    end
    
    def deleted?
      deleted_at if is_permanent?
    end

    def revive
      if active_record_3?
        _run_revive_callbacks do
          set_deleted_at nil
        end
      else
        run_callbacks :before_revive
        attempt_notifying_observers(:before_revive)
        set_deleted_at nil
        run_callbacks :after_revive
        attempt_notifying_observers(:after_revive)
      end
      self
    end

    def destroy(force = nil)
      if active_record_3?
        unless is_permanent? && (:force != force)
          return permanently_delete_records_after{ super() }
        end
      end
      destroy_with_permanent_records force
    end
    
    private
    def set_deleted_at(value)
      return self unless is_permanent?
      record = self.class
      record = record.unscoped if active_record_3?
      record = record.find(id)
      record.deleted_at = value
      begin
        # we call save! instead of update_attribute so an ActiveRecord::RecordInvalid
        # error will be raised if the record isn't valid. (This prevents reviving records that
        # disregard validation constraints,)
        record.save!
        @attributes, @attributes_cache = record.attributes, record.attributes
      rescue Exception => e
        # trigger dependent record destruction (they were revived before this record,
        # which cannot be revived due to validations)
        record.destroy
        raise e
      end
    end

    def destroy_with_permanent_records(force = nil)
      unless active_record_3?
        unless is_permanent? && (:force != force)
          return permanently_delete_records_after{ destroy_without_permanent_records }
        end
      end
      if active_record_3?
        _run_destroy_callbacks do
          deleted? || new_record? ? save : set_deleted_at(Time.now)
        end
      else
        run_callbacks :before_destroy
        deleted? || new_record? ? save : set_deleted_at(Time.now)
        run_callbacks :after_destroy
      end
      self
    end

    def revive_destroyed_dependent_records
      self.class.reflections.select do |name, reflection|
        'destroy' == reflection.options[:dependent].to_s && reflection.klass.is_permanent?
      end.each do |name, reflection|
        cardinality = reflection.macro.to_s.gsub('has_', '')
        if cardinality == 'many'
          records = send(name)
          records = records.unscoped if active_record_3?
          records = records.find(:all,
            :conditions => [
              "#{reflection.quoted_table_name}.deleted_at > ?" +
              " AND " +
              "#{reflection.quoted_table_name}.deleted_at < ?",
              deleted_at - 3.seconds,
              deleted_at + 3.seconds
            ]
          )
        elsif cardinality == 'one' or cardinality == 'belongs_to'
          if active_record_3?
            self.class.unscoped do
              records = [] << send(name)
            end
          else
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
          begin
            record = klass
            record = record.unscoped if active_record_3?
            record = record.find(id)
          rescue ActiveRecord::RecordNotFound
            next # the record has already been deleted, possibly due to another association with `:dependent => :destroy`
          end
          record.deleted_at = nil
          record.destroy(:force)
        end
      end
    end
    
    def active_record_3?
      ActiveRecord::VERSION::MAJOR >= 3
    end
  end
end

ActiveRecord::Base.send :include, PermanentRecords

