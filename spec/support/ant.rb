class Ant < ActiveRecord::Base
  belongs_to :hole
  validates :hole, presence: true

  after_revive :reactivate_ants

  def add_ant ant
    # do something like you want

    # Force reload
    Hole.not_deleted.where(id: hole.id).first.add_to_ants_cache ant
  end

  def reactivate_ants
    # Ant.unscoped.find(destroyed_ants).each { |ant| add_ant ant }
    Array(Ant.create).each { |ant| add_ant ant }
  end
end
