class Accounts < ActiveRecord::Migration
  def change

    create_table "people", :force => true do |t|
      t.string   "idstring", :limit => 80, :null => false
      t.string   "password_hash"
      t.string   "legacy_password", :limit => 40
      t.string   "first_name"
      t.string   "last_name"
      t.string   "email", :limit => 96
      t.string   "title"
      t.string   "phonenumber"
      t.string   "time_zone"
      t.datetime "email_event_at"
      t.boolean  "contributor_agreement"
      t.datetime "contributor_agreement_at"
      t.integer  "account_status"
      t.datetime "last_login_at"
      t.integer  "position_id", :default => 0
      t.integer  "location_id", :default => 0
      t.integer  "county_id", :default => 0
      t.integer  "institution_id", :default => 0
      t.boolean  "retired", :default => false
      t.boolean  "vouched", :default => false
      t.integer  "vouched_by", :default => 0
      t.datetime "vouched_at"
      t.boolean  "emailconfirmed", :default => false
      t.boolean  "is_admin", :default => false
      t.boolean  "announcements", :default => true
      t.datetime "retired_at"
      t.string   "base_login_string"
      t.integer  "login_increment"
      t.integer  "primary_account_id"
      t.string   "affiliation"
      t.text     "involvement"
      t.text     "additionaldata"
      t.timestamps
    end

    add_index "people", ["email"], :name => "email_ndx", :unique => true
    add_index "people", ["idstring"], :name => "idstring_ndx", :unique => true
    add_index "people", ["vouched", "retired"], :name => "validity_ndx"


    create_table "google_accounts", :force => true do |t|
      t.integer  "person_id",          :default => 0,     :null => false
      t.string   "username",                            :null => false
      t.boolean  "no_sync_password", :default => false
      t.string   "password",                            :null => false
      t.string   "given_name",                          :null => false
      t.string   "family_name",                         :null => false
      t.boolean  "is_admin",         :default => false
      t.boolean  "suspended",        :default => false
      t.datetime "apps_updated_at"
      t.boolean  "has_error",        :default => false
      t.text     "last_error"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "google_accounts", ["person_id"], :name => "person_ndx", :unique => true



  end

end
