ActiveRecord::Schema.define(:version => 1) do
  
  create_table :muskrats, :force => true do |t|
    t.column :name,         :string
    t.column :deleted_at,   :datetime
    t.references :hole
  end
  
  create_table :kitties, :force => true do |t|
    t.column :name,   :string
  end

  create_table :holes, :force => true do |t|
    t.integer :number
    t.datetime :deleted_at
  end
  
  create_table :moles, :force => true do |t|
    t.string :name
    t.references :hole
  end
  
  create_table :locations, :force => true do |t|
    t.string :name
    t.references :hole
    t.datetime :deleted_at
  end

end
