class Location < ActiveRecord::Base
  belongs_to :hole
  validates :hole, presence: true
  validates_uniqueness_of :name, :scope => :deleted_at
end
