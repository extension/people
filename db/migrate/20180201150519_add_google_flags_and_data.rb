class AddGoogleFlagsAndData < ActiveRecord::Migration
  def change
    add_column(:google_groups, :marked_for_removal, :boolean, null: false, default: false)
    add_column(:google_groups, :last_google_data, :text, null: true)
    add_column(:google_accounts, :last_google_data, :text, null: true)
  end
end
