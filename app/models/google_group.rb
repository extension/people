# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
class GoogleGroup < ActiveRecord::Base
  attr_accessible :community, :community_id, :group_id, :group_name, :email_permission, :apps_updated_at
  attr_accessible :has_error, :last_api_request, :connectiontype, :lists_alias
  attr_accessible :use_groups_domain, :migrated_to_groups_domain

  before_save  :set_values_from_community
  after_save :update_email_alias

  before_destroy :delete_apps_group

  belongs_to :community, unscoped: true
  has_one  :email_alias, :as => :aliasable, :dependent => :destroy

  # Google Group Names are limited to 60 characters
  validates :group_name, length: { maximum: 60 }

  def update_email_alias
    if(!self.email_alias.blank?)
      if(self.migrated_to_groups_domain)
        self.email_alias.update_attribute(:alias_type, EmailAlias::GOOGLEGROUP)
      else
        self.email_alias.update_attribute(:alias_type, EmailAlias::GOOGLEAPPS)
      end
    elsif(!self.use_groups_domain)
      self.create_email_alias(:alias_type => EmailAlias::GOOGLEAPPS)
    end
  end

  def forum_url
    if(self.use_groups_domain)
      "https://groups.google.com/a/#{Settings.googleapps_groups_domain}/d/forum/#{self.group_id}?hl=en"
    else
      "https://groups.google.com/a/extension.org/d/forum/#{self.group_id}?hl=en"
    end
  end

  def extension_domain_email
    "#{self.group_id}@extension.org"
  end

  def group_email_address
    if(self.use_groups_domain)
      "#{self.group_id}@#{Settings.googleapps_groups_domain}"
    else
      self.extension_domain_email
    end
  end

  def old_group_email_address
    if(self.migrated_to_groups_domain)
      self.extension_domain_email
    else
      self.group_email_address
    end
  end

  def group_key_for_api
    self.group_email_address
  end


  def set_values_from_community
    if(self.connectiontype == 'leaders')
      if(self.community.is_institution?)
        self.group_id = "#{self.community.shortname}-institutional-team"
        self.group_name = "#{self.community.name} (Institutional Team)"
      else
        self.group_id = "#{self.community.shortname}-leaders"
        self.group_name = "#{self.community.name} (Leaders)"
      end
    else
      self.group_id = self.community.shortname
      self.group_name = self.community.name
    end
    self.email_permission = 'Anyone'
    return true
  end

  def queue_group_update
    if(Settings.sync_google)
      if(Settings.redis_enabled)
        self.class.delay_for(5.seconds).delayed_update_apps_group(self.id)
      else
        self.update_apps_group
      end
    end
  end

  def queue_members_update
    if(Settings.sync_google)
      if(Settings.redis_enabled)
        self.class.delay_for(90.seconds).delayed_update_apps_group_members(self.id)
      else
        self.update_apps_group_members
      end
    end
  end

  def self.delayed_update_apps_group(record_id)
    if(record = find_by_id(record_id))
      record.update_apps_group
    end
  end

  def self.delayed_update_apps_group_members(record_id)
    if(record = find_by_id(record_id))
      record.update_apps_group_members
    end
  end


  def update_apps_group
    # load GoogleDirectoryApi
    gda = GoogleDirectoryApi.new
    found_group = gda.retrieve_group(self.group_key_for_api)

    # create the group if it doesnt't exist
    if(!found_group)
      created_group = gda.create_group(self.group_key_for_api, {description: self.group_name, name: self.group_name})

      if(!created_group)
        self.update_attributes({:has_error => true, :last_api_request => gda.api_log.id})
        return nil
      else
        # set the initial group settings
        groupsettings = GoogleGroupSettingsApi.new
        if(set_group = groupsettings.set_initial_group_settings(self.group_key_for_api))
          self.update_attributes({:has_error => true, :last_api_request => gda.api_log.id})
          return nil
        end
      end
    else
      updated_group = gda.update_group(self.group_key_for_api, {description: self.group_name, name: self.group_name})

      if(!updated_group)
        self.update_attributes({:has_error => true, :last_api_request => gda.api_log.id})
        return nil
      end
    end

    self.update_attributes({has_error: false, apps_updated_at: Time.now.utc, :last_api_request => gda.api_log.id})
    return self
  end

  def get_apps_group_members(gda = nil)
    if(gda.nil?)
      gda = GoogleDirectoryApi.new
    end
    gda.retrieve_group_members(self.group_key_for_api)
  end

  def map_community_members_to_emails
    if(self.use_groups_domain)
      # map the community members to an array of profile emails
      # - actual email *not* the display email
      if(self.connectiontype == 'leaders')
        community_members = self.community.leaders.map{|person| "#{person.email}"}
      else
        community_members = self.community.joined.map{|person| "#{person.email}"}
      end
    else
      # map the community members to an array of idstring@extension.org emails
      if(self.connectiontype == 'leaders')
        community_members = self.community.leaders.map{|person| "#{person.idstring}@extension.org"}
      else
        community_members = self.community.joined.map{|person| "#{person.idstring}@extension.org"}
      end
    end
    community_members
  end


  def update_apps_group_members
    # load GoogleDirectoryApi
    gda = GoogleDirectoryApi.new
    apps_group_members = self.get_apps_group_members(gda)
    if(apps_group_members.nil?)
      self.update_attributes({:has_error => true, :last_api_request => gda.api_log.id})
      return false
    end

    # inject the moderator account
    moderator_account = Person.find(Person::MODERATOR_ACCOUNT)
    if(community_members = self.map_community_members_to_emails)
      community_members << moderator_account.email
    else
      community_members = [moderator_account.email]
    end

    adds = community_members - apps_group_members
    removes = apps_group_members - community_members

    removes.each do |member_email|
      gda.remove_member_from_group(member_email, self.group_key_for_api)
    end

    adds.each do |member_email|
      is_owner = (member_email == moderator_account.email)
      gda.add_member_to_group(member_email, self.group_key_for_api,is_owner)
    end

    self.update_attributes({has_error: false, apps_updated_at: Time.now.utc, :last_api_request => gda.api_log.id})
    return true
  end

  def delete_apps_group(force_extension_domain = false)
    gda = GoogleDirectoryApi.new
    if(force_extension_domain)
      gda.delete_group(self.extension_domain_email)
    else
      gda.delete_group(self.group_key_for_api)
    end
  end

  # does not background requests, meant to be run from console
  def migrate_to_groups_domain(delete_old_group = true)
    # set flags
    self.update_attributes(use_groups_domain: true, migrated_to_groups_domain: true)

    # create new group @ google
    self.update_apps_group

    # update group members
    self.update_apps_group_members

    # schedule notifications
    Notification.create(:notification_type => Notification::GOOGLE_GROUP_MIGRATION, :notifiable => self)

    # delete old group @ google
    if(delete_old_group)
      self.delete_apps_group(true)
    end
  end

  def notification_pool
    if(self.connectiontype == 'leaders')
      self.community.people.validaccounts.where('community_connections.connectiontype = ?',"leader")
    else
      self.community.people.validaccounts
    end
  end

  def self.clear_errors
    self.update_all("has_error = 0","has_error = 1")
  end

  def self.queue_members_update_for_all_groups
    GoogleGroup.all.each do |gg|
      gg.queue_members_update
    end
  end

end
