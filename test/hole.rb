class Hole < ActiveRecord::Base
  # muskrats are permanent
  has_many :muskrats, :dependent => :destroy
  # moles are not permanent
  has_many :moles, :dependent => :destroy
  
  has_one :location, :dependent => :destroy
  has_one :unused_model, :dependent => :destroy
end