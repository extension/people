class AddAppActivities < ActiveRecord::Migration
  def change
    create_table "app_activities", :force => true do |t|
      t.integer  "person_id",        :default => 0
      t.integer  "app_id",           :default => 0
      t.string   "app_label",        :limit => 25
      t.integer  "app_source_type",  :default => 0
      t.integer  "section_id",       :default => 1
      t.string   "section_label",    :limit => 25
      t.integer  "activity_code",    :default => 0
      t.string   "activity_label",       :limit => 25
      t.string   "app_activity_label",   :limit => 25
      t.integer  "app_item_id",      :limit => 64
      t.integer  "source_id", :default => 0
      t.string   "source_model"
      t.string   "source_table"
      t.string   "ip_address",       :limit => 45
      t.string   "fingerprint",      :limit => 64
      t.text     "additionaldata"
      t.datetime "activity_at"
      t.datetime "created_at"
    end

    add_index "app_activities", ["activity_at", "person_id", "app_id", "app_source_type", "section_id", "activity_code","ip_address"], :name => "fields_ndx"
    add_index "app_activities", ["fingerprint"], :name => "fingerprint_ndx", :unique => true
    add_index "app_activities", ["app_item_id"], :name => "app_item_ndx"

  end
end
