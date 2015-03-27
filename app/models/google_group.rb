# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
class GoogleGroup < ActiveRecord::Base
  serialize :last_error
  attr_accessible :community, :community_id, :group_id, :group_name, :email_permission, :apps_updated_at, :has_error, :last_error, :connectiontype, :lists_alias

  before_save  :set_values_from_community
  after_save :update_email_alias


  belongs_to :community
  has_one  :email_alias, :as => :aliasable, :dependent => :destroy

  def update_email_alias
    if(!self.email_alias.blank?)
      self.email_alias.update_attribute(:alias_type, EmailAlias::GOOGLEAPPS)
    else
      self.create_email_alias(:alias_type => EmailAlias::GOOGLEAPPS)
    end
  end

  def forum_url
    "https://groups.google.com/a/extension.org/d/forum/#{self.group_id}?hl=en"
  end

  def group_email_address
    "#{self.group_id}@extension.org"
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
        self.class.delay_for(90.seconds).delayed_update_apps_group_members_and_owners(self.id)
      else
        self.update_apps_group_members_and_owners
      end
    end
  end

  def self.delayed_update_apps_group(record_id)
    if(record = find_by_id(record_id))
      record.update_apps_group
    end
  end


  def update_apps_group_members_and_owners
    group = update_apps_group_members
  end

  def self.delayed_update_apps_group_members_and_owners(record_id)
    if(record = find_by_id(record_id))
      record.update_apps_group_members_and_owners
    end
  end


  def update_apps_group

    # load GoogleDirectoryApi
    gda = GoogleDirectoryApi.new
    found_group = gda.retrieve_group(self.group_id)

    # create the group if it doesnt't exist
    if(!found_group)
      created_group = gda.create_group(self.group_id, {description: self.group_name, name: self.group_name})

      if(!created_group)
        self.update_attributes({:has_error => true, :last_error => gda.last_result})
        return nil
      end
    else
      updated_group = gda.update_group(self.group_id, {description: self.group_name, name: self.group_name})

      if(!updated_group)
        self.update_attributes({:has_error => true, :last_error => gda.last_result})
        return nil
      end
    end

    self.update_attributes({has_error: false, last_error: nil, apps_updated_at: Time.now.utc})
    return self
  end

  def update_apps_group_members
    # load GoogleDirectoryApi
    gda = GoogleDirectoryApi.new

    apps_group_members = gda.retrieve_group_members(self.group_id)
    if(apps_group_members.nil?)
      self.update_attributes({:has_error => true, :last_error => gda.last_result})
      return nil
    end

    # map the community members to an array of idstrings
    if(self.connectiontype == 'leaders')
      community_members = self.community.leaders.map{|person| "#{person.idstring}"}
    else
      community_members = self.community.joined.map{|person| "#{person.idstring}"}
    end

    # inject the moderator account
    moderator_account = Person.find(Person::MODERATOR_ACCOUNT)
    if(community_members)
      community_members << moderator_account.idstring
    else
      community_members = [moderator_account.idstring]
    end

    adds = community_members - apps_group_members
    removes = apps_group_members - community_members

    adds.each do |member_id|
      # split the id string back out
      gda.add_member_to_group(member_id, self.group_id)
    end

    removes.each do |member_id|
      gda.remove_member_from_group(member_id, self.group_id)
    end

    return self
  end




  def self.clear_errors
    self.update_all("has_error = 0, last_error = ''","has_error = 1")
  end
end
