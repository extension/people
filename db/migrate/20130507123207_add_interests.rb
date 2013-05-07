class AddInterests < ActiveRecord::Migration
  def change
    create_table :interests do |t|
      t.string   "name"
      t.datetime "created_at"
    end
    add_index "interests", ["name"], :name => "name_ndx", :unique => true
  

    create_table :person_interests do |t|
      t.integer  "interest_id"
      t.integer  "person_id"
      t.datetime "created_at"
    end
    add_index "person_interests", ["interest_id", "person_id"], :name => "tagging_ndx", :unique => true

  end
end
