class AddGeoNames < ActiveRecord::Migration
  def change
 
     create_table "geo_names", :force => true do |t|
      t.string  "feature_name",       :limit => 121
      t.string  "feature_class",      :limit => 51
      t.string  "state_abbreviation", :limit => 3
      t.string  "state_code",         :limit => 3
      t.string  "county",             :limit => 101
      t.string  "county_code",        :limit => 4
      t.string  "lat_dms",            :limit => 8
      t.string  "long_dms",           :limit => 9
      t.float   "lat"
      t.float   "long"
      t.string  "source_lat_dms",     :limit => 8
      t.string  "source_long_dms",    :limit => 9
      t.float   "source_lat"
      t.float   "source_long"
      t.integer "elevation"
      t.string  "map_name"
      t.string  "create_date_txt"
      t.string  "edit_date_txt"
      t.date    "create_date"
      t.date    "edit_date"
    end

    add_index "geo_names", ["feature_name", "state_abbreviation", "county"], :name => "name_state_county_ndx"

    execute("INSERT INTO geo_names SELECT * from prod_aae.geo_names")
  end

 end
