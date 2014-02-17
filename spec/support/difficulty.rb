class Difficulty < ActiveRecord::Base
  belongs_to :hole

  if ActiveRecord::VERSION::STRING == '3.0.0'
    default_scope where(:deleted_at => nil)
  else
    default_scope { where(:deleted_at => nil) }
  end
end
