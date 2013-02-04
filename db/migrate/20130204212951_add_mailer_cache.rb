class AddMailerCache < ActiveRecord::Migration
  def change

    create_table "mailer_caches", :force => true do |t|
      t.string   "hashvalue",      :limit => 40,                      :null => false
      t.integer  "person_id"
      t.integer  "notification_id"
      t.integer  "cacheable_id"
      t.string   "cacheable_type", :limit => 30
      t.integer  "open_count",                         :default => 0
      t.text     "markup",         :limit => 16777215
      t.datetime "created_at",                                        :null => false
      t.datetime "updated_at",                                        :null => false
    end

    add_index "mailer_caches", ["hashvalue"], :name => "hashvalue_ndx"
    add_index "mailer_caches", ["person_id", "open_count"], :name => "person_view_ndx"

  end

end
