# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class GoogleAccount < ActiveRecord::Base
  serialize :google_account_data
  attr_accessible :person, :person_id, :given_name, :family_name, :is_admin, :suspended, :apps_updated_at, :has_error
  attr_accessible :last_ga_login_request_at, :last_ga_login_at, :has_ga_login, :last_api_request, :marked_for_removal, :updated_at
  belongs_to :person
  before_save  :set_values_from_person

  scope :not_suspended, ->{where(suspended: false)}
  scope :suspended, ->{where(suspended: true)}
  scope :has_ga_login, ->{where(has_ga_login: true)}
  scope :active, -> { where('DATE(last_ga_login_at) >= ?',Date.today - Settings.months_for_inactive_flag.months) }

  before_destroy :delete_apps_account

  def user_key
    "#{self.username}@extension.org"
  end

  def set_values_from_person
    if(!self.new_record?)
      if(self.person.idstring.downcase != self.username)
        self.renamed_from_username = self.username
        self.username = self.person.idstring.downcase
      else
        self.username = self.person.idstring.downcase
      end
    else
      self.username = self.person.idstring.downcase
    end
    self.given_name = self.person.first_name
    self.family_name = self.person.last_name
    return true
  end


  def queue_account_update
    if(Settings.sync_google)
      if(Settings.redis_enabled)
        self.class.delay_for(5.seconds).delayed_update_apps_account(self.id)
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

  def delete_apps_account
    gda = GoogleDirectoryApi.new
    found_account = gda.retrieve_account(self.username)
    if(!found_account)
      return true
    else
      gda.delete_account(self.username)
    end
  end

  def get_apps_account
    self.update_column(:has_error,false)
    # load GoogleDirectoryApi
    gda = GoogleDirectoryApi.new
    found_account = gda.retrieve_account(self.username)
    if(!found_account)
      self.update_attributes({:has_error => true, :last_api_request => gda.api_log.id})
      return nil
    else
      self.has_error = false
      self.last_api_request = gda.api_log.id
      self.save
      return found_account  #Google::Apis::AdminDirectoryV1::User
    end
  end


  def update_apps_account
    # clear errors out
    self.update_column(:has_error,false)
    # load GoogleDirectoryApi
    gda = GoogleDirectoryApi.new
    if(!self.renamed_from_username.blank?)
      found_account = gda.retrieve_account(self.renamed_from_username)
    else
      found_account = gda.retrieve_account(self.username)
    end


    # create the account if it didn't exist
    if(found_account.nil?)
      created_account = gda.create_account(self.username,
                                           {given_name: self.given_name,
                                            family_name: self.family_name,
                                            password: self.person.password_reset,
                                            suspended: self.suspended?})
      if(!created_account)
        Honeybadger.notify("Google Account Sync Error", error_class: 'GoogleAccount', context: {google_account_id: self.id})
        self.update_attributes({:has_error => true, :last_api_request => gda.api_log.id})
        return nil
      else
        self.has_error = false
        self.last_api_request = gda.api_log.id
      end
    else
      updated_account = gda.update_account(self.username,
                                             {given_name: self.given_name,
                                              family_name: self.family_name,
                                              password: self.person.password_reset,
                                              suspended: self.suspended?})
      if(!updated_account)
        Honeybadger.notify("Google Account Sync Error", error_class: 'GoogleAccount', context: {google_account_id: self.id})
        self.update_attributes({:has_error => true, :last_api_request => gda.api_log.id})
        return nil
      else
        self.has_error = false
        self.last_api_request = gda.api_log.id
      end
    end

    self.apps_updated_at = Time.now
    self.renamed_from_username = nil
    self.save
    self.person.clear_password_reset
    return self
  end

  def self.set_last_ga_login_at
    # get the full list of last logins from google
    # load GoogleDirectoryApi
    gda = GoogleDirectoryApi.new
    user_list = gda.retrieve_last_login_for_all_accounts
    user_list.each do |email,last_login|
      if(email =~ %r{(\w+)@extension.org})
        if(ga = self.find_by_username($1))
          ga.update_attributes({last_ga_login_at: last_login, has_ga_login: true})
        end
      end
    end
    user_list.size
  end

  def self.clear_errors
    self.update_all("has_error = 0","has_error = 1")
  end
end
