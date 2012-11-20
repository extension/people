# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AuthLog < ActiveRecord::Base
  attr_accessible :person, :person_id, :site, :auth_code, :fail_code,  :authname, :ip_address

  belongs_to :person

  LOCAL_SUCCESS = 1
  LOCAL_FAILURE = 2

  REMOTE_SUCCESS = 11
  REMOTE_FAILURE = 12

  # failure codes
  AUTH_UNKNOWN = 0
  AUTH_INVALID_ID = 1
  AUTH_PASSWORD_EXPIRED = 2
  AUTH_INVALID_PASSWORD = 3
  AUTH_ACCOUNT_RETIRED = 4


  def self.log_local_success(options = {})
    required = [:person_id,:authname]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    create_parameters = {}
    create_parameters[:site] = 'local'
    create_parameters[:person_id] = options[:person_id]
    create_parameters[:auth_code] = LOCAL_SUCCESS
    create_parameters[:authname] = options[:authname]
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'

    self.create(create_parameters)

  end

  def self.log_local_failure(options = {})
    required = [:authname]
    required.each do |required_option|
      if(options[required_option].nil?)
        return false
      end
    end

    create_parameters = {}
    create_parameters[:site] = 'local'
    create_parameters[:person_id] = options[:person_id]
    create_parameters[:auth_code] = LOCAL_FAILURE
    create_parameters[:authname] = options[:authname]
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'
    create_parameters[:fail_code] = options[:fail_code] || AUTH_UNKNOWN

    self.create(create_parameters)

  end

end