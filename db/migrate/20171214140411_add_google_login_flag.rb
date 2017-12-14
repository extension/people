class AddGoogleLoginFlag < ActiveRecord::Migration
  def up
    add_column(:google_accounts, :has_ga_login, :boolean, null: true)
    execute("UPDATE google_accounts SET has_ga_login = 0 WHERE last_ga_login_at = '1970-01-01 00:00:00'")
    execute("UPDATE google_accounts SET has_ga_login = 1 WHERE last_ga_login_at > '1970-01-01 00:00:00'")
    # clear out last_ga_login_at values that are unix_timestamp 0
    execute("UPDATE google_accounts SET last_ga_login_at = NULL WHERE last_ga_login_at = '1970-01-01 00:00:00'")
  end

  def down
    remove_column(:google_accounts, :has_ga_login)
  end
end
