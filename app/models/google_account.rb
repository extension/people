# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file
require 'gappsprovisioning/provisioningapi'
include GAppsProvisioning

class GoogleAccount < ActiveRecord::Base
  attr_accessor :apps_connection
  serialize :last_error
  attr_accessible :person, :person_id, :given_name, :family_name, :is_admin, :suspended, :apps_updated_at, :has_error, :last_error
  
  GDATA_ERROR_ENTRYDOESNOTEXIST = 1301

  before_save  :set_values_from_person

  belongs_to :person

  def set_values_from_person
    self.username = self.person.idstring.downcase
    self.given_name = self.person.first_name
    self.family_name = self.person.last_name
    return true
  end


  def queue_account_update
    if(Settings.sync_google)
      if(Settings.redis_enabled)
        self.class.delay.delayed_update_apps_account(self.id)
      else
        self.update_apps_account
      end
    end
  end

  def self.delayed_update_apps_account(record_id)
    if(record = find_by_id(record_id))
      record.update_apps_account
    end
  end
  
  def update_apps_account
    self.establish_apps_connection
    
    # check for an account
    begin
      google_account = self.apps_connection.retrieve_user(self.username)
    rescue GDataError => e
      if(e.code.to_i != GDATA_ERROR_ENTRYDOESNOTEXIST)
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
    end
    
    # create the account if it didn't exist
    if(!google_account)
      begin
        if(!(password = self.person.password_reset))
          password = SecureRandom.hex(16)
        end
        google_account = self.apps_connection.create_user(self.username,self.given_name,self.family_name,password,"SHA-1")
      rescue GDataError => e
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
    end
    
    
    # update the account
    begin
      if(password = self.person.password_reset)
        google_account = self.apps_connection.update_user(self.username,
                                                                self.given_name,
                                                                self.family_name,
                                                                password,"SHA-1",
                                                                self.is_admin? ? "true" : "false",
                                                                self.suspended? ? "true" : "false",
                                                                "false")
      else
        google_account = self.apps_connection.update_user(self.username,
                                                                self.given_name,
                                                                self.family_name,
                                                                nil,nil,
                                                                self.is_admin? ? "true" : "false",
                                                                self.suspended? ? "true" : "false",
                                                                "false")
      end
    rescue GDataError => e
      self.update_attributes({:has_error => true, :last_error => e})
      return nil
    end
    
    self.touch(:apps_updated_at)  
    # if we made it here, it must have worked
    self.person.clear_password_reset
    return google_account
  end
  
  def establish_apps_connection(force_reconnect = false)
    if(self.apps_connection.nil? or force_reconnect)
      self.apps_connection = ProvisioningApi.new(Settings.googleapps_account,Settings.googleapps_secret)
    end
  end
  
  def self.retrieve_all_users
    class_apps_connection = ProvisioningApi.new(Settings.googleapps_account,Settings.googleapps_secret)
    class_apps_connection.retrieve_all_users
  end
  
  def self.clear_errors
    self.update_all("has_error = 0, last_error = ''","has_error = 1")
  end
end