class Hole < ActiveRecord::Base
  # muskrats are permanent
  has_many :muskrats, :dependent => :destroy
  # moles are not permanent
  has_many :moles, :dependent => :destroy
  
  has_one :location, :dependent => :destroy
  has_one :unused_model, :dependent => :destroy
  has_one :difficulty, :dependent => :destroy
  has_many :comments, :dependent => :destroy
end