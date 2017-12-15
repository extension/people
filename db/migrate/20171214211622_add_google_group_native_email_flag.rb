class AddGoogleGroupNativeEmailFlag < ActiveRecord::Migration
  def change
    add_column(:google_groups, :use_profile_email_addresses, :boolean, null: false, default: false)
  end
end
