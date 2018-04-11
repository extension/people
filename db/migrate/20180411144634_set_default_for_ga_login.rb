class SetDefaultForGaLogin < ActiveRecord::Migration
  def up
    execute "ALTER TABLE `prod_people`.`google_accounts` CHANGE COLUMN `has_ga_login` `has_ga_login` TINYINT(1) NOT NULL DEFAULT 0  COMMENT '' AFTER `last_ga_login_at`;"
  end
end
