class InitialSchema < ActiveRecord::Migration
  def change

    create_table "people", :force => true do |t|
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

    add_index "people", ["email"], :name => "email_ndx", :unique => true
    add_index "people", ["idstring"], :name => "idstring_ndx", :unique => true
    add_index "people", ["vouched", "retired"], :name => "validity_ndx"


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

  create_table "communities", :force => true do |t|
    t.integer  "entrytype",                             :default => 0,     :null => false
    t.string   "name",                                                     :null => false
    t.text     "description"
    t.integer  "created_by",                            :default => 0
    t.integer  "memberfilter",                          :default => 1
    t.string   "shortname"
    t.string   "public_name"
    t.text     "public_description"
    t.boolean  "is_launched",                           :default => false
    t.integer  "public_topic_id"
    t.boolean  "show_in_public_list",                   :default => false
    t.integer  "location_id",                           :default => 0
    t.string   "public_uri"
    t.string   "referer_domain"
    t.string   "institution_code",        :limit => 10
    t.boolean  "connect_to_drupal",                     :default => false
    t.integer  "drupal_node_id"
    t.boolean  "connect_to_google_apps",                :default => false
    t.boolean  "active",                                :default => true
    t.timestamps
  end

  add_index "communities", ["name"], :name => "communities_name_index", :unique => true
  add_index "communities", ["referer_domain"], :name => "index_communities_on_referer_domain"
  add_index "communities", ["shortname"], :name => "index_communities_on_shortname", :unique => true

  create_table "community_connections", :force => true do |t|
    t.integer  "person_id"
    t.integer  "community_id"
    t.string   "connectiontype"
    t.integer  "connectioncode"
    t.boolean  "sendnotifications"
    t.integer  "connected_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "community_connections", ["connectiontype"], :name => "index_communityconnections_on_connectiontype"
  add_index "community_connections", ["person_id", "community_id"], :name => "person_community_ndx", :unique => true

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

  create_table "google_groups", :force => true do |t|
    t.integer  "community_id",     :default => 0,     :null => false
    t.string   "group_id",                            :null => false
    t.string   "group_name",                          :null => false
    t.string   "email_permission",                    :null => false
    t.datetime "apps_updated_at"
    t.boolean  "has_error",        :default => false
    t.text     "last_error"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "google_groups", ["community_id"], :name => "community_ndx", :unique => true


  end
end
