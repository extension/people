class DropShareAccounts < ActiveRecord::Migration
  def up
    drop_table(:share_accounts)
  end
end
