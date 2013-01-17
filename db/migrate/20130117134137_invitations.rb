class Invitations < ActiveRecord::Migration
  def change

    create_table "invitations", :force => true do |t|
      t.integer  "created_by",                      :default => 0, :null => false
      t.string   "token",          :limit => 40,                :null => false
      t.string   "email",                                       :null => false
      t.datetime "created_at",                                  :null => false
      t.datetime "accepted_at"
      t.integer  "person_id",                 :default => 0
      t.datetime "reminder_at"
      t.integer  "reminder_count",               :default => 0
      t.text     "additionaldata"
      t.integer  "resent_count",                 :default => 0
      t.datetime "resent_at"
      t.text     "message"
      t.text     "resendmessage"
      t.integer  "status",                       :default => 0
    end

    add_index "invitations", ["person_id"], :name => "person_ndx"
    add_index "invitations", ["email"], :name => "email_ndx"
    add_index "invitations", ["token"], :name => "token_ndx"
    add_index "invitations", ["created_by"], :name => "creator_ndx"

  end

end
