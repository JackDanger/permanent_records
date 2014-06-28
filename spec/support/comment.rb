class Comment < ActiveRecord::Base
  belongs_to :hole

  default_scope { where(:deleted_at => nil) }
end
