class Hole < ActiveRecord::Base
  has_many :moles, :dependent => :destroy
end