class DropMailmanListTable < ActiveRecord::Migration
  def up
  	drop_table("mailman_lists")
  end

end
