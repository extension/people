class AddGoogleAppsConnectFlag < ActiveRecord::Migration
  def up
    add_column(:people, :connect_to_google, :boolean, null: false, default: false)
    execute "UPDATE people,google_accounts SET people.connect_to_google = 1 WHERE people.id = google_accounts.person_id"
    add_column(:google_accounts, :marked_for_removal, :boolean, null: false, default: false)
  end
end
