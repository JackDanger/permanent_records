class Hole < ActiveRecord::Base
  # Because when we're destroying a mole hole we're obviously using high explosives.
  belongs_to :dirt, :dependent => :destroy

  # muskrats are permanent
  has_many :muskrats, :dependent => :destroy
  # moles are not permanent
  has_many :moles, :dependent => :destroy

  has_many :ants, :dependent => :destroy
  has_one :location, :dependent => :destroy
  has_one :unused_model, :dependent => :destroy
  has_one :difficulty, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  serialize :options, Hash
  store :properties, :accessors => [:size] if respond_to?(:store)

  attr_accessor :youre_in_the_hole

  before_destroy :check_youre_not_in_the_hole

  private

  def check_youre_not_in_the_hole
    !youre_in_the_hole
  end
end
