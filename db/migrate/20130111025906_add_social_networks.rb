class AddSocialNetworks < ActiveRecord::Migration
  def change

    create_table "social_network_connections", :force => true do |t|
      t.integer  "person_id"
      t.string   "network",     :limit => 96
      t.string   "displayname"
      t.string   "accountid",   :limit => 96
      t.string   "description"
      t.string   "accounturl"
      t.integer  "privacy"
      t.boolean  "is_public",                 :default => false
      t.timestamps
    end

    add_index "social_network_connections", ["network", "accountid"], :name => "network_account_ndx"
    add_index "social_network_connections", ["privacy"], :name => "privacy_ndx"
    add_index "social_network_connections", ["person_id"], :name => "person_ndx"

  end


end
