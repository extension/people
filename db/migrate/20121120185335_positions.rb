class Positions < ActiveRecord::Migration
  def change

    create_table "positions", :force => true do |t|
      t.integer  "entrytype",  :default => 0, :null => false
      t.string   "name",                      :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "positions", ["name"], :name => "name_ndx", :unique => true

  end

end
