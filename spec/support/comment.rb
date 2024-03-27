# frozen_string_literal: true

class Comment < ActiveRecord::Base
  belongs_to :hole
  validates :hole, presence: true
  default_scope { where(deleted_at: nil) }
end
