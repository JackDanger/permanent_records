class Mole < ActiveRecord::Base
  belongs_to :hole
  validates :hole, presence: true
end
