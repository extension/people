class AddApplicationAdmin < ActiveRecord::Migration
  def change
  	execute "ALTER TABLE `people` ADD COLUMN `admin_flags` TEXT NULL DEFAULT NULL  AFTER `is_admin`;"
  	remove_column(:people, "is_create_admin")
  end
end
