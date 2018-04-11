class SetDefaultForGaLogin < ActiveRecord::Migration
  def up
    execute "ALTER TABLE `google_accounts` CHANGE COLUMN `has_ga_login` `has_ga_login` TINYINT(1) NOT NULL DEFAULT 0;"
  end
end
