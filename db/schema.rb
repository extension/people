# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130211155737) do

  create_table "activities", :force => true do |t|
    t.integer  "person_id",      :default => 0
    t.integer  "activityclass",  :default => 0
    t.integer  "activitycode",   :default => 0
    t.integer  "reasoncode",     :default => 0
    t.integer  "community_id",   :default => 0
    t.string   "ip_address"
    t.integer  "colleague_id",   :default => 0
    t.string   "site",           :default => "local"
    t.string   "additionalinfo"
    t.text     "additionaldata"
    t.datetime "created_at"
  end

  add_index "activities", ["created_at", "person_id", "activityclass", "activitycode", "reasoncode", "community_id"], :name => "recordsignature"

  create_table "auth_approvals", :force => true do |t|
    t.integer  "person_id",  :default => 0, :null => false
    t.string   "trust_root",                :null => false
    t.datetime "created_at",                :null => false
  end

  create_table "communities", :force => true do |t|
    t.integer  "entrytype",                            :default => 0,     :null => false
    t.string   "name",                                                    :null => false
    t.text     "description"
    t.integer  "created_by",                           :default => 0
    t.integer  "memberfilter",                         :default => 1
    t.string   "shortname"
    t.string   "public_name"
    t.text     "public_description"
    t.boolean  "is_launched",                          :default => false
    t.integer  "public_topic_id"
    t.boolean  "show_in_public_list",                  :default => false
    t.integer  "location_id",                          :default => 0
    t.string   "public_uri"
    t.string   "referer_domain"
    t.string   "institution_code",       :limit => 10
    t.boolean  "connect_to_drupal",                    :default => false
    t.integer  "drupal_node_id"
    t.boolean  "connect_to_google_apps",               :default => false
    t.boolean  "active",                               :default => true
    t.datetime "created_at",                                              :null => false
    t.datetime "updated_at",                                              :null => false
  end

  add_index "communities", ["entrytype"], :name => "entrytype_ndx"
  add_index "communities", ["name"], :name => "communities_name_index", :unique => true
  add_index "communities", ["referer_domain"], :name => "index_communities_on_referer_domain"
  add_index "communities", ["shortname"], :name => "index_communities_on_shortname", :unique => true

  create_table "community_connections", :force => true do |t|
    t.integer  "person_id"
    t.integer  "community_id"
    t.string   "connectiontype"
    t.boolean  "sendnotifications"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "community_connections", ["connectiontype"], :name => "index_communityconnections_on_connectiontype"
  add_index "community_connections", ["person_id", "community_id"], :name => "person_community_ndx", :unique => true

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

  create_table "email_aliases", :force => true do |t|
    t.string   "aliasable_type", :limit => 30, :default => "0",   :null => false
    t.integer  "aliasable_id",                 :default => 0,     :null => false
    t.string   "mail_alias",                                      :null => false
    t.string   "destination",                                     :null => false
    t.integer  "alias_type",                   :default => 0,     :null => false
    t.boolean  "disabled",                     :default => false
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
  end

  add_index "email_aliases", ["aliasable_type", "aliasable_id", "alias_type"], :name => "alisable_ndx"
  add_index "email_aliases", ["mail_alias", "destination", "disabled"], :name => "postfix_select_ndx"

  create_table "google_accounts", :force => true do |t|
    t.integer  "person_id",        :default => 0,     :null => false
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

  create_table "invitations", :force => true do |t|
    t.string   "token",              :limit => 40,                    :null => false
    t.integer  "person_id",                                           :null => false
    t.string   "email",                                               :null => false
    t.text     "invitedcommunities"
    t.text     "message"
    t.boolean  "accepted",                         :default => false
    t.integer  "accepted_by"
    t.datetime "accepted_at"
    t.boolean  "reminder_sent",                    :default => false
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
  end

  add_index "invitations", ["created_at"], :name => "created_ndx"
  add_index "invitations", ["email"], :name => "email_ndx"
  add_index "invitations", ["person_id"], :name => "person_ndx"

  create_table "locations", :force => true do |t|
    t.integer "fipsid",                     :default => 0,  :null => false
    t.integer "entrytype",                  :default => 0,  :null => false
    t.string  "name",                       :default => "", :null => false
    t.string  "abbreviation", :limit => 10, :default => "", :null => false
    t.string  "office_link"
  end

  add_index "locations", ["fipsid"], :name => "fipsid_ndx", :unique => true
  add_index "locations", ["name"], :name => "name_ndx", :unique => true

  create_table "mailman_lists", :force => true do |t|
    t.integer  "community_id"
    t.string   "name",                :limit => 50
    t.string   "password"
    t.datetime "last_mailman_update"
    t.string   "connectiontype"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "mailman_lists", ["community_id", "connectiontype"], :name => "community_type_ndx", :unique => true
  add_index "mailman_lists", ["name"], :name => "name_ndx", :unique => true

  create_table "notifications", :force => true do |t|
    t.integer  "notifiable_id"
    t.string   "notifiable_type",   :limit => 30
    t.integer  "notification_type",                                  :null => false
    t.datetime "delivery_time",                                      :null => false
    t.boolean  "processed",                       :default => false, :null => false
    t.text     "additionaldata"
    t.text     "results"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
  end

  create_table "people", :force => true do |t|
    t.string   "idstring",                 :limit => 80,                    :null => false
    t.string   "password_hash"
    t.string   "legacy_password",          :limit => 40
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email",                    :limit => 96
    t.string   "title"
    t.string   "phonenumber"
    t.string   "time_zone"
    t.datetime "email_event_at"
    t.boolean  "contributor_agreement"
    t.datetime "contributor_agreement_at"
    t.integer  "account_status"
    t.datetime "last_activity_at"
    t.integer  "position_id",                            :default => 0
    t.integer  "location_id",                            :default => 0
    t.integer  "county_id",                              :default => 0
    t.integer  "institution_id",                         :default => 0
    t.boolean  "retired",                                :default => false
    t.boolean  "vouched",                                :default => false
    t.integer  "vouched_by",                             :default => 0
    t.datetime "vouched_at"
    t.boolean  "emailconfirmed",                         :default => false
    t.boolean  "is_admin",                               :default => false
    t.boolean  "announcements",                          :default => true
    t.datetime "retired_at"
    t.string   "base_login_string"
    t.integer  "login_increment"
    t.integer  "primary_account_id"
    t.string   "affiliation"
    t.text     "involvement"
    t.integer  "invitation_id"
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
  end

  add_index "people", ["email"], :name => "email_ndx", :unique => true
  add_index "people", ["idstring"], :name => "idstring_ndx", :unique => true
  add_index "people", ["vouched", "retired"], :name => "validity_ndx"

  create_table "positions", :force => true do |t|
    t.integer  "entrytype",  :default => 0, :null => false
    t.string   "name",                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "positions", ["name"], :name => "name_ndx", :unique => true

  create_table "sent_emails", :force => true do |t|
    t.string   "hashvalue",       :limit => 40,                      :null => false
    t.integer  "person_id"
    t.string   "email"
    t.integer  "notification_id"
    t.integer  "open_count",                          :default => 0
    t.text     "markup",          :limit => 16777215
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
  end

  add_index "sent_emails", ["hashvalue"], :name => "hashvalue_ndx"
  add_index "sent_emails", ["person_id", "open_count"], :name => "person_view_ndx"

  create_table "social_network_connections", :force => true do |t|
    t.integer  "person_id"
    t.integer  "social_network_id"
    t.string   "network_name"
    t.string   "custom_network_name"
    t.string   "accountid",           :limit => 96
    t.string   "accounturl"
    t.integer  "privacy"
    t.boolean  "is_public",                         :default => false
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
  end

  add_index "social_network_connections", ["person_id", "social_network_id", "accountid"], :name => "person_network_account_ndx"
  add_index "social_network_connections", ["privacy"], :name => "privacy_ndx"

  create_table "social_networks", :force => true do |t|
    t.string   "name",              :limit => 96
    t.string   "display_name"
    t.string   "url_format"
    t.text     "url_format_notice"
    t.boolean  "editable_url"
    t.boolean  "autocomplete"
    t.boolean  "active",                          :default => true
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
  end

  add_index "social_networks", ["name"], :name => "name_ndx", :unique => true

end
