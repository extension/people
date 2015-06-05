# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class GoogleAccount < ActiveRecord::Base
  serialize :last_error
  attr_accessible :person, :person_id, :given_name, :family_name, :is_admin, :suspended, :apps_updated_at, :has_error, :last_error
  belongs_to :person
  before_save  :set_values_from_person

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

  def update_apps_account
    # load GoogleDirectoryApi
    gda = GoogleDirectoryApi.new
    if(!self.renamed_from_username.blank?)
      found_account = gda.retrieve_account(self.renamed_from_username)
    else
      found_account = gda.retrieve_account(self.username)
    end

    # create the account if it didn't exist
    if(!found_account)
      created_account = gda.create_account(self.username,
                                           {given_name: self.given_name,
                                            family_name: self.family_name,
                                            password: self.person.password_reset,
                                            suspended: self.suspended?})

      if(!created_account)
        self.update_attributes({:has_error => true, :last_error => gda.last_result})
        return nil
      end
    else
      user_key = gda.last_result["id"]
      updated_account = gda.update_account(user_key,
                                           self.username,
                                           {given_name: self.given_name,
                                            family_name: self.family_name,
                                            password: self.person.password_reset,
                                            suspended: self.suspended?})

      if(!updated_account)
        self.update_attributes({:has_error => true, :last_error => gda.last_result})
        return nil
      end
    end

    self.touch(:apps_updated_at)
    # if we made it here, it must have worked
    self.update_column(:renamed_from_username,nil)
    self.person.clear_password_reset
    return self
  end

  def self.clear_errors
    self.update_all("has_error = 0, last_error = ''","has_error = 1")
  end
end
