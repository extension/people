class AddAuthenticationFlags < ActiveRecord::Migration
  def change
    add_column(:google_accounts, :random_google_password_set, :boolean, null: false, default: false)
    add_column(:people, :next_signin_required, :boolean, null: false, default: false)
  end
end
