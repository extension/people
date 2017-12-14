# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class GoogleAccount < ActiveRecord::Base
  serialize :last_error
  serialize :google_account_data
  attr_accessible :person, :person_id, :given_name, :family_name, :is_admin, :suspended, :apps_updated_at, :has_error, :last_error
  attr_accessible :last_ga_login_request_at, :last_ga_login_at
  belongs_to :person
  before_save  :set_values_from_person

  scope :not_suspended, ->{where(suspended: false)}
  scope :suspended, ->{where(suspended: true)}
  scope :has_ga_login, ->{where(has_ga_login: true)}
  scope :active, -> { where('DATE(last_ga_login_at) >= ?',Date.today - Settings.months_for_inactive_flag.months) }


  def get_google_account_data
    gda = GoogleDirectoryApi.new
    if(!self.renamed_from_username.blank?)
      found_account = gda.retrieve_account(self.renamed_from_username)
    else
      found_account = gda.retrieve_account(self.username)
    end

    if(found_account)
      gda.last_result
    else
      nil
    end
  end

  # if I restructure update_account, this method exists to use the account data
  # we have from the account update, it now just gets it again when it already
  # had it in the directory api calls, but in lieu of modifying the directory api calls
  # for now, it's just abstraction silliness or maybe syntactic sugar, yeah, syntactic semantic sugar
  def set_last_ga_login_values_from_google_account_data(google_account_data,save_values = true)
    if(!google_account_data.blank?)
      self.last_ga_login_request_at = Time.now
      begin
        ga_last_login_time = Time.parse(google_account_data['lastLoginTime'])
        if(ga_last_login_time.to_i > 0)
          self.last_ga_login_at = ga_last_login_time
          self.has_ga_login = true
        else
          self.last_ga_login_at = nil
          self.has_ga_login = false
        end
      rescue
        # time parse failure
        self.last_ga_login_at = nil
        self.has_ga_login = nil
      end

      if(save_values)
        self.save
      end
    end
    self
  end

  def update_last_ga_login_at
    self.set_last_ga_login_values_from_google_account_data(self.get_google_account_data)
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

  def queue_update_last_ga_login_at
    if(Settings.redis_enabled)
      self.class.delay_for(5.seconds).delayed_update_last_ga_login_at(self.id)
    else
      self.update_last_ga_login_at
    end
  end

  def self.delayed_update_apps_account(record_id)
    if(record = find_by_id(record_id))
      record.update_apps_account
    end
  end

  def self.delayed_update_last_ga_login_at(record_id)
    if(record = find_by_id(record_id))
      record.update_last_ga_login_at
    end
  end

  def update_apps_account
    # clear errors out
    self.update_attributes(has_error: false, last_error: nil)
    # load GoogleDirectoryApi
    gda = GoogleDirectoryApi.new
    if(!self.renamed_from_username.blank?)
      found_account = gda.retrieve_account(self.renamed_from_username)
    else
      found_account = gda.retrieve_account(self.username)
    end

    # # is the password reset field blank now? then set a random one
    # # so that we can get the account updated or created
    # begin
    #   if(!google_password = self.person.password_reset)
    #     self.person.password_reset = SecureRandom.hex(16)
    #   end
    # rescue PasswordDecryptionError => e
    #   Honeybadger.notify("Google Account Sync Error")
    #   self.update_attributes({:has_error => true, :last_error => e.message})
    #   return nil
    # end

    # create the account if it didn't exist
    if(!found_account)
      begin
        created_account = gda.create_account(self.username,
                                             {given_name: self.given_name,
                                              family_name: self.family_name,
                                              password: self.person.password_reset,
                                              suspended: self.suspended?})
      rescue StandardError => e
        Honeybadger.notify("Google Account Sync Error", error_class: 'GoogleAccount', context: {google_account_id: self.id})
        self.update_attributes({:has_error => true, :last_error => e.message})
        return nil
      end

      if(!created_account)
        Honeybadger.notify("Google Account Sync Error", error_class: 'GoogleAccount', context: {google_account_id: self.id})
        self.update_attributes({:has_error => true, :last_error => gda.last_result})
        return nil
      end
    else
      user_key = gda.last_result["id"]
      begin
        updated_account = gda.update_account(user_key,
                                             self.username,
                                             {given_name: self.given_name,
                                              family_name: self.family_name,
                                              password: self.person.password_reset,
                                              suspended: self.suspended?})
      rescue StandardError => e
        Honeybadger.notify("Google Account Sync Error", error_class: 'GoogleAccount', context: {google_account_id: self.id})
        self.update_attributes({:has_error => true, :last_error => e.message})
        return nil
      end

      if(!updated_account)
        Honeybadger.notify("Google Account Sync Error", error_class: 'GoogleAccount', context: {google_account_id: self.id})
        self.update_attributes({:has_error => true, :last_error => gda.last_result})
        return nil
      end
    end

    self.touch(:apps_updated_at)
    # if we made it here, it must have worked
    self.update_column(:renamed_from_username,nil)
    self.person.clear_password_reset
    # retrieve the account again for good measure and set last google login
    self.update_last_ga_login_at
    return self
  end

  def self.clear_errors
    self.update_all("has_error = 0, last_error = ''","has_error = 1")
  end
end
