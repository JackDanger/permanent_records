class House < ActiveRecord::Base
  has_many :rooms, dependent: :destroy
  validates_associated :rooms

  default_scope -> { where(deleted_at: nil) }
end
