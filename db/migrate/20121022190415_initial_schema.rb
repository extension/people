class InitialSchema < ActiveRecord::Migration
  def change

    create_table "accounts", :force => true do |t|
      t.string   "idstring", :limit => 80, :null => false
      t.string   "password_digest"
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
      t.text     "additionaldata"
      t.timestamps
    end

    add_index "accounts", ["email"], :name => "email_ndx", :unique => true
    add_index "accounts", ["idstring"], :name => "idstring_ndx", :unique => true
    add_index "accounts", ["vouched", "retired"], :name => "validity_ndx"


    create_table "counties", :force => true do |t|
      t.integer "fipsid",                    :default => 0,  :null => false
      t.integer "location_id",               :default => 0,  :null => false
      t.integer "state_fipsid",              :default => 0,  :null => false
      t.string  "countycode",   :limit => 3, :default => "", :null => false
      t.string  "name",                      :default => "", :null => false
      t.string  "censusclass",  :limit => 2, :default => "", :null => false
    end

    add_index "counties", ["fipsid"], :name => "fipsid_ndx", :unique => true
    add_index "counties", ["location_id"], :name => "location_ndx"
    add_index "counties", ["name"], :name => "name_ndx"
    add_index "counties", ["state_fipsid"], :name => "state_fipsid_ndx"

    create_table "locations", :force => true do |t|
      t.integer "fipsid",                     :default => 0,  :null => false
      t.integer "entrytype",                  :default => 0,  :null => false
      t.string  "name",                       :default => "", :null => false
      t.string  "abbreviation", :limit => 10, :default => "", :null => false
      t.string  "office_link"
    end

    add_index "locations", ["fipsid"], :name => "fipsid_ndx", :unique => true
    add_index "locations", ["name"], :name => "name_ndx", :unique => true

    create_table "positions", :force => true do |t|
      t.integer  "entrytype",  :default => 0, :null => false
      t.string   "name",                      :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "positions", ["name"], :name => "name_ndx", :unique => true

  end
end
