class Hole < ActiveRecord::Base
  # muskrats are permanent
  has_many :muskrats, :dependent => :destroy
  # moles are not permanent
  has_many :moles, :dependent => :destroy
end