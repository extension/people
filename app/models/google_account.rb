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
    self.username = self.person.idstring.downcase
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
    found_account = gda.retrieve_account(self)

    # create the account if it didn't exist
    if(!found_account)
      created_account = gda.create_account(self)

      if(!created_account)
        self.update_attributes({:has_error => true, :last_error => gda.last_result})
        return nil
      end
    else
      updated_account = gda.update_account(self)

      if(!updated_account)
        self.update_attributes({:has_error => true, :last_error => gda.last_result})
        return nil
      end
    end

    self.touch(:apps_updated_at)
    # if we made it here, it must have worked
    self.person.clear_password_reset
    return google_account_data
  end

  def self.clear_errors
    self.update_all("has_error = 0, last_error = ''","has_error = 1")
  end
end
