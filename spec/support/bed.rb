# frozen_string_literal: true

class Bed < ActiveRecord::Base
  has_one :kitty
end
