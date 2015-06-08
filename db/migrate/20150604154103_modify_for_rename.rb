class ModifyForRename < ActiveRecord::Migration
  def up
    add_column(:account_syncs, 'is_rename', :boolean, default: false)
    add_column(:google_accounts,'renamed_from_username',:string)


    # facilitates google apps forward
    add_column(:people,'google_apps_email',:boolean, default: false)
    add_column(:people,'email_forward',:string)


    # run the data transformation here to set the google_apps_email flag
    execute "UPDATE people,email_aliases SET people.google_apps_email = 1 where email_aliases.aliasable_type = 'Person' and email_aliases.aliasable_id = people.id and email_aliases.alias_type = #{EmailAlias::GOOGLEAPPS}"
    # set the google apps flag for persons back to forward
    execute "UPDATE email_aliases SET email_aliases.alias_type = #{EmailAlias::FORWARD} where email_aliases.aliasable_type = 'Person' and email_aliases.alias_type = #{EmailAlias::GOOGLEAPPS}"

    # set the email_forward field for those with custom forwards currently - hardcoded "2" was the previous "custom_forward" code, which is no more
    execute "UPDATE people,email_aliases SET people.email_forward = email_aliases.destination where email_aliases.aliasable_type = 'Person' and email_aliases.aliasable_id = people.id and email_aliases.alias_type = 2"
    # dump alias_type = '2'
    execute "UPDATE email_aliases SET email_aliases.alias_type = #{EmailAlias::FORWARD} where email_aliases.aliasable_type = 'Person' and email_aliases.alias_type = 2"

    # dump the current aliasable index
    remove_index(:email_aliases, name: 'alisable_ndx')
    add_index "email_aliases", ["aliasable_type", "aliasable_id", "alias_type", "mail_alias", "destination"], :name => "alias_ndx", :unique => true

    # set the email_forward for -admin accounts
    Person.reset_column_information
    Person.where("primary_account_id IS NOT NULL").each do |p|
      primary = p.primary_account
      p.update_column(:email_forward,primary.idstring)
    end

    # create or update aliases for everyone!
    Person.find_each do |p|
      p.create_or_update_forwarding_email_alias
    end

  end
end
