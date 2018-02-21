class AddSignupEmails < ActiveRecord::Migration
  def change

    create_table "signup_emails", :force => true do |t|
      t.string   "token"
      t.string   "email",                    :limit => 96
      t.boolean  "confirmed"
      t.integer  :referer_track_id
      t.integer  :invitation_id
      t.integer  :person_id
      t.datetime "created_at",                        :null => false
      t.datetime "updated_at",                        :null => false
    end

  end
end
