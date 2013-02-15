# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Activity < ActiveRecord::Base
  ## includes

  ## attributes
  serialize :additionaldata
  attr_accessible :person, :person_id, :site, :activityclass, :activitycode, :reasoncode,  :additionalinfo, :additionaldata, :ip_address, :community, :community_id

  ## validations

  ## filters

  ## associations
  belongs_to :person
  belongs_to :colleague, :class_name => "Person", :foreign_key => "colleague_id"
  belongs_to :community

  ## scopes

  #scope :community, where("activitycode BETWEEN #{Activity::COMMUNITY_ACTIVITY_START} AND #{Activity::COMMUNITY_ACTIVITY_END}")


  ## constants
  #### activity types
  AUTHENTICATION = 1
  PEOPLE = 2
  COMMUNITY = 3
  ADMIN = 4

  ## activity codes

  # PEOPLE
  AUTH_LOCAL_SUCCESS = 1
  AUTH_LOCAL_FAILURE = 2

  AUTH_REMOTE_SUCCESS = 11
  AUTH_REMOTE_FAILURE = 12

    # reason codes for failure conditions
    AUTH_UNKNOWN = 0
    AUTH_INVALID_ID = 1
    AUTH_PASSWORD_EXPIRED = 2
    AUTH_INVALID_PASSWORD = 3
    AUTH_ACCOUNT_RETIRED = 4

  SIGNUP = 101
  INVITATION = 102
  VOUCHED_FOR = 104
  UPDATE_PROFILE = 105
  INVITATION_ACCEPTED = 109
  REVIEW_REQUEST = 110

  # COMMUNITY
  COMMUNITY_CREATE = 200
  COMMUNITY_JOIN = 201
  COMMUNITY_WANTSTOJOIN = 202
  COMMUNITY_LEFT= 203
  COMMUNITY_ACCEPT_INVITATION= 205
  COMMUNITY_DECLINE_INVITATION= 206
  COMMUNITY_NOWANTSTOJOIN = 207
  COMMUNITY_INTEREST = 208
  COMMUNITY_NOINTEREST = 209

  COMMUNITY_INVITEDASLEADER = 210
  COMMUNITY_INVITEDASMEMBER = 211
  COMMUNITY_ADDEDASLEADER = 212
  COMMUNITY_ADDEDASMEMBER = 213
  COMMUNITY_REMOVEDASLEADER = 214
  COMMUNITY_REMOVEDASMEMBER = 215
  COMMUNITY_INVITATIONRESCINDED = 216

  COMMUNITY_UPDATE_INFORMATION = 401
  COMMUNITY_CREATED_LIST = 402


  # ADMIN
  ENABLE_ACCOUNT  = 1003
  RETIRE_ACCOUNT  = 1004
  


  def self.log_local_auth_success(options = {})
    required = [:person_id,:authname]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    create_parameters = {}
    create_parameters[:site] = 'local'
    create_parameters[:person_id] = options[:person_id]
    create_parameters[:activityclass] = AUTHENTICATION
    create_parameters[:activitycode] = AUTH_LOCAL_SUCCESS
    create_parameters[:additionalinfo] = options[:authname]
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'

    self.create(create_parameters)

  end

  def self.log_local_auth_failure(options = {})
    required = [:authname]
    required.each do |required_option|
      if(options[required_option].nil?)
        return false
      end
    end

    create_parameters = {}
    create_parameters[:site] = 'local'
    create_parameters[:person_id] = options[:person_id]
    create_parameters[:activityclass] = AUTHENTICATION
    create_parameters[:activitycode] = AUTH_LOCAL_FAILURE
    create_parameters[:additionalinfo] = options[:authname]
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'
    create_parameters[:reasoncode] = options[:fail_code] || AUTH_UNKNOWN

    self.create(create_parameters)

  end

end