class MilfamTransition < ActiveRecord::Migration
  def change
    add_column(:sites, :default_role, :integer, null: false, default: SiteRole::EDITOR)
    Site.reset_column_information
    site = Site.where(label: 'homepage').first
    site.update_column(:default_role,SiteRole::READER)

    site = Site.where(label: 'milfam').first
    site.update_column(:default_role,SiteRole::READER)
    milfam_authors = Community.find(1764)
    SiteRole.create(permissable: milfam_authors, site: site, permission: SiteRole::EDITOR)
  end
end
