ActiveRecord::Schema.define(:version => 1) do
  
  create_table :muskrats do |t|
    t.column :name,         :string
    t.column :deleted_at,   :datetime
    t.references :hole
  end
  
  create_table :kitties do |t|
    t.column :name,   :string
  end

  create_table :holes do |t|
    t.integer :number
    t.datetime :deleted_at
  end
  
  create_table :moles do |t|
    t.string :name
    t.references :hole
  end

end
