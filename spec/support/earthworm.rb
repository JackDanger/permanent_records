class Earthworm < ActiveRecord::Base
  belongs_to :dirt
  validates :dirt, presence: true
  # Earthworms have been known to complain if they're left on their deathbeds
  # without any dirt
  before_destroy :complain!

  def complain!
    raise "Where's my dirt?!" if Dirt.not_deleted.find(dirt_id).nil?
  end
end
