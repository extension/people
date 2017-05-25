class AddProfileLinks < ActiveRecord::Migration
  def change

    create_table "profile_links", :force => true do |t|
      t.integer  "person_id"
      t.integer  "link_type"
      t.string   "label"
      t.text     "url"
      t.string   "fingerprint"
      t.boolean  "is_public"
      t.string   "host"
      t.text     "path"
      t.integer  "check_status"
      t.integer  "error_count",            :default => 0
      t.datetime "last_check_at"
      t.integer  "last_check_status"
      t.boolean  "last_check_response"
      t.string   "last_check_code"
      t.text     "last_check_information"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "profile_links", ["person_id", "fingerprint"], :name => "person_fingerprint_ndx", :unique => true
  end
end
