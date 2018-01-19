class ChangeGoogleAccounts < ActiveRecord::Migration
  def change
    remove_column(:google_accounts, :last_error)
    add_column(:google_accounts, :last_api_request, :integer)
  end

  def down
  end
end
