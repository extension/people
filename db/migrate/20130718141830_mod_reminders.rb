class ModReminders < ActiveRecord::Migration
  def up
    execute "ALTER TABLE `people` ADD COLUMN `account_reminders` INT(11) NULL DEFAULT 0 AFTER `last_account_reminder`;"
    execute "UPDATE people SET account_reminders = 1 where last_account_reminder IS NOT NULL"
  end
end
