class Kitty < ActiveRecord::Base
  has_and_belongs_to_many :beds, dependent: :destroy
end
