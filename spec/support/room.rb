class Room < ActiveRecord::Base
  belongs_to :house
  validates :house, presence: true

  default_scope -> { where(deleted_at: nil) }
end
