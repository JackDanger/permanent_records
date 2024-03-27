# frozen_string_literal: true

ActiveRecord::Schema.define(version: 1) do
  create_table :ants, force: true do |t|
    t.column :name,         :string
    t.column :deleted_at,   :datetime
    t.references :hole
    t.integer :any_hole_id
    t.string :any_hole_type
  end

  create_table :muskrats, force: true do |t|
    t.column :name,         :string
    t.column :deleted_at,   :datetime
    t.references :hole
  end

  create_table :beds, force: true do |t|
    t.column :name, :string
  end

  create_table :kitties, force: true do |t|
    t.column :name, :string
    t.references :bed
  end

  create_table :beds_kitties, force: true do |t|
    t.references :kitty
    t.references :bed
  end

  create_table :holes, force: true do |t|
    t.integer :number
    t.text :options
    t.text :properties
    t.references :dirt
    t.integer :ants_count, default: 0
    t.datetime :deleted_at
  end

  create_table :moles, force: true do |t|
    t.string :name
    t.references :hole
  end

  create_table :locations, force: true do |t|
    t.string :name
    t.references :hole
    t.integer :parent_id
    t.datetime :deleted_at
  end

  create_table :comments, force: true do |t|
    t.string :text
    t.references :hole
    t.datetime :deleted_at
  end

  create_table :difficulties, force: true do |t|
    t.string :name
    t.references :hole
    t.datetime :deleted_at
  end

  create_table :unused_models, force: true do |t|
    t.string :name
    t.references :hole
    t.datetime :deleted_at
  end

  create_table :holes_meerkats, force: true do |t|
    t.references :hole
    t.references :meerkat
  end

  create_table :meerkats, force: true do |t|
    t.string :name
  end

  create_table :dirts, force: true do |t|
    t.string :color
    t.datetime :deleted_at
  end

  create_table :earthworms, force: true do |t|
    t.references :dirt
  end

  create_table :houses, force: true do |t|
    t.datetime :deleted_at
  end

  create_table :rooms, force: true do |t|
    t.references :house
    t.datetime :deleted_at
  end
end
