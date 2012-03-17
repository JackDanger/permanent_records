class Dirt < ActiveRecord::Base
  has_one :hole
  has_one :earthworm, :dependent => :destroy
end
