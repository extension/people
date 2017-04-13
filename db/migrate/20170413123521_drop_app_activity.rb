class DropAppActivity < ActiveRecord::Migration
  def up
    drop_table(:app_activities)
  end

  def down
  end
end
