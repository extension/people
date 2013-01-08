class CreateLists < ActiveRecord::Migration
  def change
    create_table "mailman_lists", :force => true do |t|
      t.integer  "community_id"
      t.string   "name",                :limit => 50
      t.string   "password"
      t.datetime "last_mailman_update"
      t.string   "connectiontype"
      t.timestamps
    end

    add_index "mailman_lists", ["name"], :name => "name_ndx", :unique => true
    add_index "mailman_lists", ["community_id","connectiontype"], :name => "community_type_ndx", :unique => true
  end

end
