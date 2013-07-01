class ListCleanup < ActiveRecord::Migration
  def change
    # google groups columns associated with lists
    execute "ALTER TABLE `google_groups` ADD COLUMN `connectiontype` VARCHAR(255) NULL DEFAULT 'joined' AFTER `community_id`;"
    execute "ALTER TABLE `google_groups` ADD COLUMN `lists_alias` VARCHAR(255) NULL DEFAULT NULL  AFTER `connectiontype`;"

    # email alias type changes
    execute "UPDATE email_aliases set alias_type = #{EmailAlias::GOOGLEAPPS} where alias_type = 101"
    execute "UPDATE email_aliases set alias_type = #{EmailAlias::NOWHERE} where alias_type = 102"

    # lists alias
    execute "UPDATE google_groups SET lists_alias = 'dev-deploys' WHERE group_id = 'dev-commits'"
    execute "UPDATE google_groups SET lists_alias = 'engineering' WHERE group_id = 'engineering'"
    execute "UPDATE google_groups SET lists_alias = 'extension-staff' WHERE group_id = 'extensionstaff'"
    execute "UPDATE google_groups SET lists_alias = 'extech' WHERE group_id = 'extech'"

    # gg index
    remove_index "google_groups", :name => "community_ndx"
    add_index "google_groups", ["community_id"], :name => "community_ndx"

  end

end
