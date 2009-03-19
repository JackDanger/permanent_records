module PermanentRecords
  VERSION = '1.0.1'
  def self.included(base)
    if base.respond_to?(:named_scope)
      base.named_scope :deleted, :conditions => {:deleted_at => true}
      base.named_scope :not_deleted, :conditions => { :deleted_at => nil }
    else
      base.extend LegacyScopes
    end
    base.send :include, InstanceMethods
    base.define_callbacks :before_revive, :after_revive
    base.alias_method_chain :destroy, :permanent_record_force
    base.alias_method_chain :destroy_without_callbacks, :permanent_record
  end
  
  module LegacyScopes
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
      run_callbacks :before_revive
      set_deleted_at nil
      run_callbacks :after_revive
      self
    end
    
    def set_deleted_at(value)
      return self unless is_permanent?
      record = self.class.find(id)
      record.update_attribute(:deleted_at, value)
      @attributes, @attributes_cache = record.attributes, record.attributes
    end
    
    def destroy_with_permanent_record_force(force = nil)
      @force_permanent_record_destroy = (:force == force)
      destroy_without_permanent_record_force
    end
    
    def destroy_without_callbacks_with_permanent_record
      return destroy_without_callbacks_without_permanent_record if @force_permanent_record_destroy || !is_permanent?
      unless deleted? || new_record?
        set_deleted_at Time.now
      end
      self
    end
  end
end
