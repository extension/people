class AddAuthApprovals < ActiveRecord::Migration
  def change
    create_table "auth_approvals", :force => true do |t|
      t.integer  "person_id",    :default => 0, :null => false
      t.string   "trust_root",                :null => false
      t.datetime "created_at",                :null => false
    end
  end

end
