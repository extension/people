class AddBrowseFilters < ActiveRecord::Migration
  def change

    create_table "browse_filters", :force => true do |t|
      t.integer  "created_by"
      t.text     "settings"
      t.text     "notifylist"
      t.string   "fingerprint", :limit => 40
      t.boolean  "dump_in_progress"
      t.datetime "dump_last_generated_at"
      t.float    "dump_last_runtime"
      t.integer  "dump_last_filesize"
      t.timestamps
    end

    add_index "browse_filters", ["fingerprint"], :name => "fingerprint_ndx", :unique => true

    BrowseFilter.reset_column_information
    BrowseFilter.create(settings: {}, created_by: Person.system_id)

  end
end
