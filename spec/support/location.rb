class Location < ActiveRecord::Base
  belongs_to :hole
  validates :hole, presence: true, unless: :zone?
  validates_uniqueness_of :name, scope: :deleted_at
  has_many :zones,
           class_name: 'Location',
           foreign_key: 'parent_id',
           dependent: :destroy

  private

  def zone?
    parent_id.present?
  end
end
