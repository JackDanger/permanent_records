# frozen_string_literal: true

class Difficulty < ActiveRecord::Base
  belongs_to :hole

  default_scope { where(deleted_at: nil) }

  validates :hole, presence: true
end
