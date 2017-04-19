class AddAppActivity < ActiveRecord::Migration
  def change

    create_table "app_activities", :force => true do |t|
      t.integer  "trackable_id",          :default => 0
      t.string   "trackable_type",        :limit => 25
      t.integer  "app_id",                :default => 0
      t.integer  "activity_code",         :default => 0
      t.integer  "section_id",            :default => 1
      t.string   "section_label",         :limit => 25
      t.string   "source_model"
      t.integer  "year",               :default => 0
      t.integer  "month",              :default => 0
      t.integer  "quarter",            :default => 0
      t.integer  "item_count",         :default => 0
      t.integer  "activity_count",     :default => 0
      t.integer  "person_count",       :default => 0
      t.integer  "pool_count",         :default => 0
      t.text     "additionaldata",     :limit => 16777215
      t.timestamps
    end

    add_index "app_activities", ["trackable_id","trackable_type","activity_code","year","month","quarter"], :name => "trackable_ndx", :unique => true


  end

  def down
  end
end
