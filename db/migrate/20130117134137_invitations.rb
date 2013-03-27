class Invitations < ActiveRecord::Migration
  def change

    create_table "invitations", :force => true do |t|
      t.integer  "person_id",      :null => false
      t.string   "email",          :null => false
      t.text     "invitedcommunities"
      t.text     "message"
      t.boolean  "accepted",  :default => false
      t.integer  "accepted_by"
      t.datetime "accepted_at"
      t.boolean  "reminder_sent",  :default => false
      t.timestamps
    end

    add_index "invitations", ["person_id"], :name => "person_ndx"
    add_index "invitations", ["email"], :name => "email_ndx"
    add_index "invitations", ["created_at"], :name => "created_ndx"

  end

end
