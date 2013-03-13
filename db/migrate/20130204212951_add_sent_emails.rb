class AddSentEmails < ActiveRecord::Migration
  def change

    create_table "sent_emails", :force => true do |t|
      t.string   "hashvalue",      :limit => 40,                      :null => false
      t.integer  "person_id"
      t.integer  "notification_id"
      t.integer  "open_count",                         :default => 0
      t.text     "markup",         :limit => 16777215
      t.datetime "created_at",                                        :null => false
      t.datetime "updated_at",                                        :null => false
    end

    add_index "sent_emails", ["hashvalue"], :name => "hashvalue_ndx"
    add_index "sent_emails", ["person_id", "open_count"], :name => "person_view_ndx"

  end

end
