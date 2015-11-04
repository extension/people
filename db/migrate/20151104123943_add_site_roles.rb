class AddSiteRoles < ActiveRecord::Migration
  def up

    create_table "sites", :force => true do |t|
      t.string  "label"
      t.string  "uri"
      t.string  "dev_uri"
      t.string  "database"
      t.string  "dev_database"
      t.string  "apptype"
      t.timestamps
    end

    add_index "sites", ["label"], :name => 'site_ndx', :unique => true
    Site.reset_column_information

    # create the site list
    Site.create(label: 'homepage',
                uri: 'https://about.extension.org',
                dev_uri: 'https://dev.extension.org',
                database: 'prod_about',
                dev_database: 'dev_about',
                apptype: 'wordpress')

    Site.create(label: 'create',
                uri: 'http://create.extension.org',
                dev_uri: 'http://dev-create.extension.org',
                database: 'prod_create',
                dev_database: 'dev_create',
                apptype: 'drupal')

    Site.create(label: 'articles',
                uri: 'http://www.extension.org',
                dev_uri: 'http://dev-articles.extension.org',
                database: 'prod_frontporch',
                dev_database: 'dev_frontporch',
                apptype: 'rails')

    Site.create(label: 'learn',
                uri: 'https://learn.extension.org',
                dev_uri: 'https://dev-learn.extension.org',
                database: 'prod_learn',
                dev_database: 'dev_learn',
                apptype: 'rails')

    Site.create(label: 'ask',
                uri: 'https://ask.extension.org',
                dev_uri: 'https://dev-ask.extension.org',
                database: 'prod_ask',
                dev_database: 'dev_ask',
                apptype: 'rails')

    Site.create(label: 'milfam',
                uri: 'http://militaryfamilies.extension.org',
                database: 'prod_milfam',
                apptype: 'wordpress')


    create_table "site_roles", :force => true do |t|
      t.integer  "permissable_id"
      t.string   "permissable_type"
      t.integer  "site_id"
      t.integer  "permission"
      t.timestamps
    end

    add_index "site_roles", ["permissable_id","permissable_type","site_id"], :name => 'role_ndx', :unique => true
    SiteRole.reset_column_information

    # convert admin roles
    AdminRole.all.each do |ar|
      site = Site.where(label: ar.applabel).first
      SiteRole.create(permissable: ar.person, site: site, permission: SiteRole::ADMINISTRATOR)
    end

    # create a site role for the core team and homepage authors group
    core_team = Community.find(30)
    homepage_authors = Community.find(1736)
    site = Site.where(label: 'homepage').first
    SiteRole.create(permissable: core_team, site: site, permission: SiteRole::EDITOR)
    SiteRole.create(permissable: homepage_authors, site: site, permission: SiteRole::WRITER)



  end
end
