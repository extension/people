class AddAppActivity < ActiveRecord::Migration
  def change

    create_table "app_activities", :force => true do |t|
      t.integer  "trackable_id",       :default => 0
      t.string   "trackable_type",     :limit => 25
      t.integer  "app_id",             :default => 0
      t.string   "app_label",          :limit => 25
      t.integer  "app_source_type",    :default => 0
      t.integer  "section_id",         :default => 1
      t.string   "section_label",      :limit => 25
      t.integer  "activity_code",      :default => 0
      t.string   "activity_label",     :limit => 25
      t.string   "app_activity_label", :limit => 25
      t.string   "source_model"
      t.integer  "year"
      t.integer  "month"
      t.integer  "quarter"
      t.integer  "item_count"
      t.integer  "activity_count"
      t.text     "additionaldata"
      t.datetime "created_at"
    end

    add_index "app_activities", ["trackable_id","trackable_type","activity_code","year","month","quarter"], :name => "trackable_ndx"


  end

  def down
  end
end
