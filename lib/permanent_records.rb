require 'active_record'
module PermanentRecords

  def self.included(base)
    base.extend Scopes
    base.send :include, InstanceMethods
    base.alias_method_chain :destroy, :permanent_record
  end
  
  module Scopes
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
      return self if is_permanent?
      record = self.class.find(id)
      record.update_attribute(:deleted_at, nil)
      record
    end
    
    def destroy_with_permanent_record(force = nil)
      if :force == force || !is_permanent?
        destroy_without_permanent_record
      else
        update_attribute(:deleted_at, Time.now)
        freeze
        self
      end
    end
  end
end