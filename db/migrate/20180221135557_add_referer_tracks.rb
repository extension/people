class AddRefererTracks < ActiveRecord::Migration
  def change
    create_table "referer_tracks", :force => true do |t|
      t.string   "ipaddr"
      t.text     "referer"
      t.text     "user_agent"
      t.integer  "load_count",         :default => 1, :null => false
      t.datetime "expires_at",                        :null => false
      t.datetime "created_at",                        :null => false
      t.datetime "updated_at",                        :null => false
    end
  end
end
