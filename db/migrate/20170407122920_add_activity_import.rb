class AddActivityImport < ActiveRecord::Migration
  def change
    create_table "activity_imports", :force => true do |t|
      t.string   "item"
      t.string   "operation"
      t.datetime "started"
      t.datetime "finished"
      t.float    "run_time"
      t.boolean  "success"
      t.text     "additionaldata"
      t.timestamps
    end
  end

  def down
  end
end
