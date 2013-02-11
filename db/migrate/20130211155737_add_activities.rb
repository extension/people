class AddActivities < ActiveRecord::Migration
  def change

  create_table "activities", :force => true do |t|
    t.integer  "person_id",               :default => 0
    t.integer  "activityclass",           :default => 0
    t.integer  "activitycode",            :default => 0
    t.integer  "community_id",            :default => 0
    t.string   "ip_address"
    t.integer  "colleague_id",            :default => 0
    t.string   "site"
    t.text     "description"
    t.text     "additionaldata"
    t.datetime "created_at"
  end

  add_index "activities", ["created_at", "person_id", "activityclass", "activitycode", "community_id"], :name => "recordsignature", :unique => true

  end

end
