# frozen_string_literal: true

class Muskrat < ActiveRecord::Base
  belongs_to :hole
  validates :hole, presence: true
end
