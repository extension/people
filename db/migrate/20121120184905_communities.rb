class Communities < ActiveRecord::Migration
  def change

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
      t.boolean  "publishing_community",                   :default => false
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
    add_index "communities", ["entrytype"], :name => "entrytype_ndx"

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
