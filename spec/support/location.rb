class Location < ActiveRecord::Base
  belongs_to :hole
  validates :hole, presence: true
  validates_uniqueness_of :name, scope: :deleted_at
  has_many :zones,
           class_name: 'Location',
           foreign_key: 'parent_id',
           dependent: :destroy
end
