class Location < ActiveRecord::Base
  belongs_to :hole
  
  validates :name, :uniqueness => {:scope => :deleted_at}
end