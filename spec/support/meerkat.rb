class Meerkat < ActiveRecord::Base
  has_and_belongs_to_many :holes
end
