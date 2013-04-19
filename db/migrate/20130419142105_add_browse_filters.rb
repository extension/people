class AddBrowseFilters < ActiveRecord::Migration
  def change

    create_table "browse_filters", :force => true do |t|
      t.integer  "created_by"
      t.text     "settings"
      t.string   "fingerprint", :limit => 40
      t.timestamps
    end

    add_index "browse_filters", ["fingerprint"], :name => "fingerprint_ndx", :unique => true

  end
end
