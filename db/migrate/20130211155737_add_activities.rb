class AddActivities < ActiveRecord::Migration
  def change

  create_table "activities", :force => true do |t|
    t.integer  "person_id",               :default => 0
    t.integer  "activityclass",           :default => 0
    t.integer  "activitycode",            :default => 0
    t.integer  "reasoncode",              :default => 0
    t.integer  "community_id",            :default => 0
    t.string   "ip_address"
    t.integer  "colleague_id",            :default => 0
    t.string   "site",                    :default => 'local'
    t.boolean  "is_private",              :default => false
    t.string   "additionalinfo"
    t.text     "additionaldata"
    t.datetime "created_at"
  end

  add_index "activities", ["created_at", "person_id", "activityclass", "activitycode", "reasoncode", "community_id"], :name => "recordsignature"

  end

end
