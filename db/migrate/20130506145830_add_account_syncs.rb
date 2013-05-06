class AddAccountSyncs < ActiveRecord::Migration
  def change

    create_table "account_syncs", :force => true do |t|
      t.integer  "person_id"
      t.boolean  "processed", default: false
      t.timestamps
    end

    add_index "account_syncs", ["person_id"], :name => "person_ndx"

  end
end
