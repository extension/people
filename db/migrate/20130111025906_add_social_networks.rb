class AddSocialNetworks < ActiveRecord::Migration
  def change

    create_table "social_networks", :force => true do |t|
      t.string  "name",     :limit => 96
      t.string  "display_name"
      t.string  "url_format"
      t.text    "url_format_notice"
      t.boolean "active", :default => true
      t.timestamps
    end

    add_index "social_networks", ["name"], :name => "name_ndx", :unique => true

    create_table "social_network_connections", :force => true do |t|
      t.integer  "person_id"
      t.integer  "social_network_id"
      t.string   "network_name"
      t.string   "custom_network_name"
      t.string   "accountid",   :limit => 96
      t.string   "accounturl"
      t.boolean  "is_public",                 :default => false
      t.timestamps
    end

    add_index "social_network_connections", ["person_id", "social_network_id", "accountid", "is_public"], :name => "person_network_account_ndx"

  end


end
