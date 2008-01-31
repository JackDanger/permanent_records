
require File.expand_path(File.dirname(__FILE__) + "/muskrat")
require File.expand_path(File.dirname(__FILE__) + "/kitty")

ActiveRecord::Schema.define(:version => 1) do
  
  create_table :muskrats do |t|
    t.column :name,         :string
    t.column :deleted_at,   :datetime
  end
  
  create_table :kitties do |t|
    t.column :name,   :string
  end
  
end
