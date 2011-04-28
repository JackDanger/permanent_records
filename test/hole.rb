class Hole < ActiveRecord::Base
  # muskrats are permanent
  has_many :muskrats, :dependent => :destroy
  # moles are not permanent
  has_many :moles, :dependent => :destroy
  
  before_destroy :about_to_destroy
  after_destroy :already_destroyed
  
  def about_to_destroy
    @saw_about_to_destroy = true
  end
  
  def already_destroyed
    @saw_after_destroy = true
  end
end