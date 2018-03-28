class AddActivityIndexes < ActiveRecord::Migration
  def up
    add_index "activities", ["person_id"], :name => "person_id_ndx"
    add_index "activities", ["colleague_id"], :name => "colleague_id_ndx"
  end

  def down
  end
end
