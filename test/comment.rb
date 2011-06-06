class Comment < ActiveRecord::Base
  belongs_to :hole
  
  if ActiveRecord::VERSION::MAJOR >= 3
    default_scope where(:deleted_at => nil)
  else
    def self.unscoped
      self
    end
  end
end