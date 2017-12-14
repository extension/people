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

ActiveRecord::Schema.define(:version => 20171214140411) do

  create_table "account_syncs", :force => true do |t|
    t.integer  "person_id"
    t.boolean  "processed",         :default => false
    t.boolean  "success"
    t.boolean  "process_on_create", :default => false
    t.text     "errors"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.boolean  "is_rename",         :default => false
  end

  add_index "account_syncs", ["person_id"], :name => "person_ndx"

  create_table "activities", :force => true do |t|
    t.integer  "person_id",      :default => 0
    t.integer  "activityclass",  :default => 0
    t.integer  "activitycode",   :default => 0
    t.integer  "reasoncode",     :default => 0
    t.integer  "community_id",   :default => 0
    t.string   "ip_address"
    t.integer  "colleague_id",   :default => 0
    t.string   "site",           :default => "local"
    t.boolean  "is_private",     :default => false
    t.string   "additionalinfo"
    t.text     "additionaldata"
    t.datetime "created_at"
  end

  add_index "activities", ["created_at", "person_id", "activityclass", "activitycode", "reasoncode", "community_id"], :name => "recordsignature"
  add_index "activities", ["ip_address"], :name => "ip_ndx"

  create_table "activity_imports", :force => true do |t|
    t.string   "item"
    t.string   "operation"
    t.datetime "started"
    t.datetime "finished"
    t.float    "run_time"
    t.boolean  "success"
    t.text     "additionaldata"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "admin_roles", :force => true do |t|
    t.integer  "person_id"
    t.string   "applabel"
    t.datetime "created_at"
  end

  add_index "admin_roles", ["person_id", "applabel"], :name => "admin_ndx", :unique => true

  create_table "auth_approvals", :force => true do |t|
    t.integer  "person_id",  :default => 0, :null => false
    t.string   "trust_root",                :null => false
    t.datetime "created_at",                :null => false
  end

  create_table "browse_filters", :force => true do |t|
    t.integer  "created_by"
    t.text     "settings"
    t.text     "notifylist"
    t.string   "fingerprint",            :limit => 40
    t.boolean  "dump_in_progress"
    t.datetime "dump_last_generated_at"
    t.float    "dump_last_runtime"
    t.integer  "dump_last_filesize"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
  end

  add_index "browse_filters", ["fingerprint"], :name => "fingerprint_ndx", :unique => true

  create_table "communities", :force => true do |t|
    t.integer  "entrytype",              :default => 0,     :null => false
    t.string   "name",                                      :null => false
    t.text     "description"
    t.integer  "created_by",             :default => 0
    t.integer  "memberfilter",           :default => 1
    t.string   "shortname"
    t.boolean  "publishing_community",   :default => false
    t.integer  "location_id",            :default => 0
    t.boolean  "connect_to_drupal",      :default => false
    t.integer  "drupal_node_id"
    t.boolean  "connect_to_google_apps", :default => false
    t.boolean  "active",                 :default => true
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "community_masthead"
    t.integer  "blog_id"
    t.integer  "primary_contact_id"
    t.integer  "membership_level",       :default => 0,     :null => false
  end

  add_index "communities", ["entrytype"], :name => "entrytype_ndx"
  add_index "communities", ["name"], :name => "communities_name_index", :unique => true
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

  create_table "community_member_syncs", :force => true do |t|
    t.integer  "person_id"
    t.integer  "community_id"
    t.boolean  "processed",         :default => false
    t.boolean  "success"
    t.boolean  "process_on_create", :default => false
    t.text     "errors"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
  end

  add_index "community_member_syncs", ["person_id", "community_id"], :name => "community_person_ndx"

  create_table "community_syncs", :force => true do |t|
    t.integer  "community_id"
    t.boolean  "processed",         :default => false
    t.boolean  "success"
    t.boolean  "process_on_create", :default => false
    t.text     "errors"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
  end

  add_index "community_syncs", ["community_id"], :name => "community_ndx"

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

  add_index "email_aliases", ["aliasable_type", "aliasable_id", "alias_type", "mail_alias", "destination"], :name => "alias_ndx", :unique => true
  add_index "email_aliases", ["mail_alias", "destination", "disabled"], :name => "postfix_select_ndx"

  create_table "extension_regions", :force => true do |t|
    t.string   "shortname"
    t.string   "label"
    t.string   "association_url"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "google_accounts", :force => true do |t|
    t.integer  "person_id",                :default => 0,     :null => false
    t.string   "username",                                    :null => false
    t.string   "given_name",                                  :null => false
    t.string   "family_name",                                 :null => false
    t.boolean  "is_admin",                 :default => false
    t.boolean  "suspended",                :default => false
    t.datetime "apps_updated_at"
    t.boolean  "has_error",                :default => false
    t.text     "last_error"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "renamed_from_username"
    t.datetime "last_ga_login_request_at"
    t.datetime "last_ga_login_at"
    t.boolean  "has_ga_login"
  end

  add_index "google_accounts", ["person_id"], :name => "person_ndx", :unique => true

  create_table "google_api_logs", :force => true do |t|
    t.datetime "created_at"
    t.string   "api_method"
    t.string   "group_id"
    t.string   "account_id"
    t.integer  "resultcode"
    t.text     "errordata"
  end

  create_table "google_groups", :force => true do |t|
    t.integer  "community_id",     :default => 0,        :null => false
    t.string   "connectiontype",   :default => "joined"
    t.string   "lists_alias"
    t.string   "group_id",                               :null => false
    t.string   "group_name",                             :null => false
    t.string   "email_permission",                       :null => false
    t.datetime "apps_updated_at"
    t.boolean  "has_error",        :default => false
    t.text     "last_error"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "google_groups", ["community_id"], :name => "community_ndx"

  create_table "institutional_regions", :force => true do |t|
    t.integer  "extension_region_id"
    t.integer  "institution_id"
    t.datetime "created_at"
  end

  add_index "institutional_regions", ["extension_region_id", "institution_id"], :name => "region_ndx", :unique => true

  create_table "interests", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
  end

  add_index "interests", ["name"], :name => "name_ndx", :unique => true

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

  create_table "notifications", :force => true do |t|
    t.integer  "notifiable_id"
    t.string   "notifiable_type",   :limit => 30
    t.integer  "notification_type",                                  :null => false
    t.datetime "delivery_time",                                      :null => false
    t.boolean  "processed",                       :default => false, :null => false
    t.boolean  "process_on_create",               :default => false
    t.text     "additionaldata"
    t.text     "results"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
  end

  create_table "people", :force => true do |t|
    t.string   "idstring",                 :limit => 80,                    :null => false
    t.string   "password_hash"
    t.string   "legacy_password",          :limit => 40
    t.text     "password_reset"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email",                    :limit => 96
    t.string   "previous_email",           :limit => 96
    t.string   "title"
    t.string   "phone"
    t.string   "time_zone"
    t.datetime "email_confirmed_at"
    t.boolean  "contributor_agreement"
    t.datetime "contributor_agreement_at"
    t.integer  "account_status"
    t.datetime "last_activity_at"
    t.datetime "last_account_reminder"
    t.integer  "account_reminders",                      :default => 0
    t.integer  "position_id",                            :default => 0
    t.integer  "location_id",                            :default => 0
    t.integer  "county_id",                              :default => 0
    t.integer  "institution_id",                         :default => 0
    t.boolean  "vouched",                                :default => false
    t.integer  "vouched_by",                             :default => 0
    t.datetime "vouched_at"
    t.boolean  "email_confirmed",                        :default => false
    t.boolean  "is_admin",                               :default => false
    t.boolean  "announcements",                          :default => true
    t.boolean  "retired",                                :default => false
    t.string   "base_login_string"
    t.integer  "login_increment"
    t.integer  "primary_account_id"
    t.string   "affiliation"
    t.text     "biography"
    t.text     "involvement"
    t.integer  "invitation_id"
    t.string   "reset_token",              :limit => 40
    t.integer  "aae_id"
    t.integer  "learn_id"
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
    t.boolean  "google_apps_email",                      :default => false
    t.datetime "tou_accepted_at"
    t.string   "slack_user_id"
    t.string   "avatar"
    t.boolean  "is_systems_account",                     :default => false
    t.boolean  "display_extension_email",                :default => false, :null => false
    t.integer  "campus_id"
    t.datetime "retired_at"
  end

  add_index "people", ["email"], :name => "email_ndx", :unique => true
  add_index "people", ["idstring"], :name => "idstring_ndx", :unique => true
  add_index "people", ["reset_token"], :name => "token_ndx"
  add_index "people", ["vouched", "retired"], :name => "validity_ndx"

  create_table "person_interests", :force => true do |t|
    t.integer  "interest_id"
    t.integer  "person_id"
    t.datetime "created_at"
  end

  add_index "person_interests", ["interest_id", "person_id"], :name => "tagging_ndx", :unique => true

  create_table "positions", :force => true do |t|
    t.integer  "entrytype",  :default => 0, :null => false
    t.string   "name",                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "positions", ["name"], :name => "name_ndx", :unique => true

  create_table "profile_public_settings", :force => true do |t|
    t.integer  "person_id"
    t.string   "item"
    t.boolean  "is_public",  :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "profile_public_settings", ["person_id"], :name => "person_ndx"

  create_table "retired_accounts", :force => true do |t|
    t.integer  "person_id",             :null => false
    t.integer  "retiring_colleague_id"
    t.string   "explanation"
    t.text     "communities"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "retired_accounts", ["person_id"], :name => "person_ndx", :unique => true

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

  create_table "share_accounts", :force => true do |t|
    t.integer "person_id", :default => 0, :null => false
    t.string  "username",                 :null => false
    t.string  "password",                 :null => false
  end

  add_index "share_accounts", ["person_id"], :name => "person_ndx", :unique => true

  create_table "site_roles", :force => true do |t|
    t.integer  "permissable_id"
    t.string   "permissable_type"
    t.integer  "site_id"
    t.integer  "permission"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "site_roles", ["permissable_id", "permissable_type", "site_id"], :name => "role_ndx", :unique => true

  create_table "sites", :force => true do |t|
    t.string   "label"
    t.string   "uri"
    t.string   "dev_uri"
    t.string   "database"
    t.string   "dev_database"
    t.string   "apptype"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "default_role", :default => 2, :null => false
  end

  add_index "sites", ["label"], :name => "site_ndx", :unique => true

  create_table "slack_bots", :force => true do |t|
    t.integer  "person_id",          :default => 1
    t.string   "slack_channel_id"
    t.string   "slack_channel_name"
    t.string   "slack_user_id"
    t.string   "slack_user_name"
    t.string   "command"
    t.text     "commandtext"
    t.datetime "created_at"
  end

  create_table "social_network_connections", :force => true do |t|
    t.integer  "person_id"
    t.integer  "social_network_id"
    t.string   "network_name"
    t.string   "custom_network_name"
    t.string   "accountid",           :limit => 96
    t.string   "accounturl"
    t.boolean  "is_public",                         :default => false
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
  end

  add_index "social_network_connections", ["person_id", "social_network_id", "accountid", "is_public"], :name => "person_network_account_ndx"

  create_table "social_networks", :force => true do |t|
    t.string   "name",              :limit => 96
    t.string   "display_name"
    t.string   "url_format"
    t.text     "url_format_notice"
    t.boolean  "active",                          :default => true
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
  end

  add_index "social_networks", ["name"], :name => "name_ndx", :unique => true

end
