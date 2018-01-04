class AddGoogleGroupDomainFlag < ActiveRecord::Migration
  def change
    add_column(:google_groups, :use_groups_domain, :boolean, null: false, default: false)
  end
end
