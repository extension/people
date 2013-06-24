# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file
require 'gappsprovisioning/provisioningapi'
include GAppsProvisioning

class GoogleGroup < ActiveRecord::Base
  attr_accessor :apps_connection
  serialize :last_error
  attr_accessible :community, :community_id, :group_id, :group_name, :email_permission, :apps_updated_at, :has_error, :last_error

  GDATA_ERROR_ENTRYDOESNOTEXIST = 1301

  before_save  :set_values_from_community
  
  belongs_to :community

  def set_values_from_community
    self.group_id = self.community.shortname
    self.group_name = self.community.name
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
        self.class.delay_for(5.seconds).delayed_update_apps_group_members_and_owners(self.id)
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
    if(group = update_apps_group_members)
      update_apps_group_owners
    end
  end
  
  def self.delayed_update_apps_group_members_and_owners(record_id)
    if(record = find_by_id(record_id))
      record.update_apps_group_members_and_owners
    end
  end


  def update_apps_group
    self.establish_apps_connection
    
    # check for a group - a little different than the google
    # account check - there's no single group retrieval, so
    # we'll just check for the apps_updated_at timestamp
    
    # create the group if it didn't exist
    if(self.apps_updated_at.blank?)
      begin
        google_group = self.apps_connection.create_group(self.group_id,[self.group_name,self.group_name,self.email_permission])
      rescue GDataError => e
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
    else    
      # update the group
      begin
        google_group = self.apps_connection.update_group(self.group_id,[self.group_name,self.group_name,self.email_permission])

      rescue GDataError => e
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
    end
    
    self.update_attributes({has_error: false, last_error: nil, apps_updated_at: Time.now.utc})
    # if we made it here, it must have worked
    return google_group
  end
  
  def update_apps_group_members
    # update the group for good measure
    
    if(!(google_group = self.update_apps_group))
      return nil
    else
      # get the members @google
      begin
        apps_group_members = self.apps_connection.retrieve_all_members(self.group_id).map(&:member_id)
      rescue GDataError => e
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
      
      # map the community members to an array of "blah@extension.org"
      community_members = self.community.joined.map{|person| "#{person.idstring}@extension.org"}
      
      adds = community_members - apps_group_members
      removes = apps_group_members - community_members
      
      # add the adds/remove the removes
      begin
        adds.each do |member_id|
          member = self.apps_connection.add_member_to_group(member_id, self.group_id)
        end
        
        removes.each do |member_id|
          member = self.apps_connection.remove_member_from_group(member_id, self.group_id)
        end
      rescue
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
      
      return google_group
    end
  end
  
  # owners *have* to be a member of the group first, so run this after update_apps_group_members
  def update_apps_group_owners
    self.establish_apps_connection

    # get the owners @google
    begin
      apps_group_owners = self.apps_connection.retrieve_all_owners(self.group_id).map(&:owner_id)
    rescue GDataError => e
      self.update_attributes({:has_error => true, :last_error => e})
      return nil
    end
    
    # map the community members to an array of "blah@extension.org"
    community_owners = self.community.leaders.map{|person| "#{person.idstring}@extension.org"}
    
    adds = community_owners - apps_group_owners
    removes = apps_group_owners - community_owners
    
    results = {:adds => 0, :removes => 0}
    # add the adds/remove the removes
    begin
      adds.each do |owner_id|
        owner = self.apps_connection.add_owner_to_group(owner_id, self.group_id)
        results[:adds] += 1
      end
      
      removes.each do |owner_id|
        owner = self.apps_connection.remove_owner_from_group(owner_id, self.group_id)
        results[:removes] += 1
      end
    rescue
      self.update_attributes({:has_error => true, :last_error => e})
      return nil
    end
    
    results
  end
      
    
  
  def establish_apps_connection(force_reconnect = false)
    if(self.apps_connection.nil? or force_reconnect)
      self.apps_connection = ProvisioningApi.new(Settings.googleapps_account,Settings.googleapps_secret)
    end
  end
  
  def self.retrieve_all_groups
    class_apps_connection = ProvisioningApi.new(Settings.googleapps_account,Settings.googleapps_secret)
    class_apps_connection.retrieve_all_groups
  end
  
  def self.clear_errors
    self.update_all("has_error = 0, last_error = ''","has_error = 1")
  end  
end