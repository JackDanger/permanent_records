# frozen_string_literal: true

class Dirt < ActiveRecord::Base
  has_one :hole
  # validates :hole, presence: true
  has_one :earthworm, dependent: :destroy
end
