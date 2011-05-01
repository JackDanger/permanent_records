module PermanentRecords
  def self.included(base)

    base.send :include, InstanceMethods

    # Rails 3
    if ActiveRecord::VERSION::MAJOR >= 3
      base.scope :deleted, :conditions => 'deleted_at IS NOT NULL'
      base.scope :not_deleted, :conditions => { :deleted_at => nil }
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

    def destroyed?
      deleted? || super
    end
    
    def revive
      # Rails 3
      if ActiveRecord::VERSION::MAJOR >= 3
        _run_revive_callbacks do
          set_deleted_at nil
        end
      else
        run_callbacks :before_revive
        set_deleted_at nil
        run_callbacks :after_revive
      end
      self
    end
    
    def set_deleted_at(value)
      return self unless is_permanent?
      record = self.class.unscoped.find(id)
      record.update_attribute(:deleted_at, value)
      @attributes, @attributes_cache = record.attributes, record.attributes
    end

    def destroy(force = nil)
      if ActiveRecord::VERSION::MAJOR >= 3
        return super() unless is_permanent? && (:force != force)
      end
      destroy_with_permanent_records force
    end

    def destroy_with_permanent_records(force = nil)
      if ActiveRecord::VERSION::MAJOR < 3
        return destroy_without_permanent_records unless is_permanent? && (:force != force)
      end
      unless deleted? || new_record?
        set_deleted_at Time.now
      end
      # Rails 3
      if ActiveRecord::VERSION::MAJOR >= 3
        _run_destroy_callbacks do
          save
        end
      else
        run_callbacks :before_destroy
        save
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
          records = send(name).unscoped.find(:all,
                          :conditions => [
                            "#{reflection.quoted_table_name}.deleted_at > ?" +
                            " AND " +
                            "#{reflection.quoted_table_name}.deleted_at < ?",
                            deleted_at - 3.seconds,
                            deleted_at + 3.seconds
                          ]
                        )
        elsif cardinality == 'one'
          self.class.unscoped do
            records = [] << send(name)
          end
        end
        records.compact.each do |dependent|
          dependent.revive
        end

        # and update the reflection cache
        send(name, :reload)
      end
    end
  end
end

ActiveRecord::Base.send :include, PermanentRecords

