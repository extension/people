class AddProfilePublicSettings < ActiveRecord::Migration
  def change

    create_table "profile_public_settings", :force => true do |t|
      t.integer  "person_id"
      t.string   "item"
      t.boolean  "is_public",  :default => false
      t.timestamps
    end

    add_index "profile_public_settings", ["person_id"], :name => "person_ndx"

  end

end
