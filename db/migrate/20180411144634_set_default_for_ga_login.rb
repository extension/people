class SetDefaultForGaLogin < ActiveRecord::Migration
  def up
    execut "UPDATE google_accounts set has_ga_login = 0 where has_ga_login IS NULL;"
    execute "ALTER TABLE `google_accounts` CHANGE COLUMN `has_ga_login` `has_ga_login` TINYINT(1) NOT NULL DEFAULT 0;"
  end
end
