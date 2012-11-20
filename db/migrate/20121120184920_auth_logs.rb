class AuthLogs < ActiveRecord::Migration
  def change

    create_table "auth_logs", :force => true do |t|
      t.integer  "person_id"
      t.integer  "auth_code",                 :null => false
      t.integer  "fail_code"
      t.string   "authname"
      t.string   "site"
      t.string   "ip_address"
      t.datetime "created_at"
    end

    add_index "auth_logs", ["person_id"], :name => "person_ndx"
  end

end
