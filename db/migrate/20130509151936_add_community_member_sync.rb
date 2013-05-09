class AddCommunityMemberSync < ActiveRecord::Migration
  def change

    create_table "community_member_syncs", :force => true do |t|
      t.integer  "person_id"
      t.integer  "community_id"
      t.boolean  "processed", default: false
      t.boolean  "success"
      t.boolean  "sync_on_create", default: false
      t.text     "errors"
      t.timestamps
    end

    add_index "community_member_syncs", ["person_id","community_id"], :name => "community_person_ndx"

  end
end
