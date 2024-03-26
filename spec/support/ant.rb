# frozen_string_literal: true

class Ant < ActiveRecord::Base
  belongs_to :hole, counter_cache: true
  belongs_to :any_hole, polymorphic: true, counter_cache: true

  validates :hole, presence: true, unless: :any_hole

  def add_ant(ant)
    # do something like you want

    # Force reload
    Hole.not_deleted.where(id: hole.id).first.add_to_ants_cache ant
  end
end
