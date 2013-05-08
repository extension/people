class AddCommunitySync < ActiveRecord::Migration
  def change

    create_table "community_syncs", :force => true do |t|
      t.integer  "community_id"
      t.boolean  "processed", default: false
      t.boolean  "sync_on_create", default: false
      t.timestamps
    end

    add_index "community_syncs", ["community_id"], :name => "community_ndx"

  end
end
