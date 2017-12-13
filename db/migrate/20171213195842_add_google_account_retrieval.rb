class AddGoogleAccountRetrieval < ActiveRecord::Migration
  def change
    add_column(:google_accounts, :last_ga_login_request_at, :datetime, null: true)
    add_column(:google_accounts, :last_ga_login_at, :datetime, null: true)
  end

  def down
  end
end
