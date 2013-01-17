class EmailAliases < ActiveRecord::Migration
  def change

    create_table "email_aliases", :force => true do |t|
      t.string   "aliasable_type",   :limit => 30,   :default => 0,     :null => false
      t.integer  "aliasable_id",     :default => 0,     :null => false
      t.string   "mail_alias",                          :null => false
      t.string   "destination",                         :null => false
      t.integer  "alias_type",       :default => 0,     :null => false
      t.boolean  "disabled",         :default => false
      t.timestamps 
    end

    add_index "email_aliases", ["mail_alias","destination","disabled"], :name => "postfix_select_ndx"
    add_index "email_aliases", ["aliasable_type","aliasable_id","alias_type"], :name => "alisable_ndx"
  end

end
