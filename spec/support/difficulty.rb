class Difficulty < ActiveRecord::Base
  belongs_to :hole
  validates :hole, presence: true
  
  if ActiveRecord::VERSION::STRING == '3.0.0'
    default_scope where(:deleted_at => nil)
  else
    default_scope { where(:deleted_at => nil) }
  end
end
