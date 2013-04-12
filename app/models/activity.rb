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
  attr_accessible :person, :person_id, :site, :activityclass, :activitycode, :reasoncode,  :additionalinfo, :additionaldata, :ip_address, :community, :community_id, :colleague_id, :colleague

  ## validations

  ## filters
  before_save :set_activity_class

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

  AUTHENTICATION_RANGE = (1..99)
  PEOPLE_RANGE = (100..199)
  COMMUNITY_RANGE = (200..499)
  ADMIN_RANGE = (1000...1099)

  ## activity codes

  # PEOPLE
  AUTH_LOCAL_SUCCESS                  = 1
  AUTH_LOCAL_FAILURE                  = 2

  AUTH_REMOTE_SUCCESS                 = 11
  AUTH_REMOTE_FAILURE                 = 12

  # reason codes for failure conditions
  AUTH_UNKNOWN                        = 0
  AUTH_INVALID_ID                     = 1
  AUTH_PASSWORD_EXPIRED               = 2
  AUTH_INVALID_PASSWORD               = 3
  AUTH_ACCOUNT_RETIRED                = 4

  SIGNUP                              = 101
  INVITATION                          = 102
  VOUCHED_FOR                         = 104
  UPDATE_PROFILE                      = 105
  EMAIL_CHANGE                        = 106
  PASSWORD_CHANGE                     = 107
  CONFIRMED_EMAIL                     = 108
  INVITATION_ACCEPTED                 = 109
  REVIEW_REQUEST                      = 110
  UPDATE_COLLEAGUE_PROFILE            = 111

  # COMMUNITY
  COMMUNITY_CREATE                    = 200
  COMMUNITY_JOIN                      = 201
  COMMUNITY_PENDING                   = 202
  COMMUNITY_LEFT                      = 203
  COMMUNITY_ACCEPT_INVITATION         = 205
  COMMUNITY_DECLINE_INVITATION        = 206
  COMMUNITY_REMOVE_PENDING            = 207

  COMMUNITY_INVITEDASLEADER           = 210
  COMMUNITY_INVITEDASMEMBER           = 211
  COMMUNITY_ADDEDASLEADER             = 212
  COMMUNITY_ADDEDASMEMBER             = 213
  COMMUNITY_REMOVEDASLEADER           = 214
  COMMUNITY_REMOVEDASMEMBER           = 215
  COMMUNITY_RESCINDINVITATION         = 216

  COMMUNITY_UPDATE_INFORMATION        = 401
  COMMUNITY_CREATED_LIST              = 402


  # ADMIN
  ENABLE_ACCOUNT                      = 1003
  RETIRE_ACCOUNT                      = 1004


  def set_activity_class
    if AUTHENTICATION_RANGE.include?(self.activitycode)
      self.activityclass = AUTHENTICATION
    elsif PEOPLE_RANGE.include?(self.activitycode)
      self.activityclass = PEOPLE
    elsif COMMUNITY_RANGE.include?(self.activitycode)
      self.activityclass = COMMUNITY
    elsif ADMIN_RANGE.include?(self.activitycode)
      self.activityclass = ADMIN
    end
  end

  def self.log_activity(options = {})
    required = [:person_id,:activitycode]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    create_parameters = {}
    create_parameters[:person_id] = options[:person_id]
    create_parameters[:site] = options[:site] || 'local'
    create_parameters[:activitycode] = options[:activitycode]
    create_parameters[:additionalinfo] = options[:additionalinfo]
    create_parameters[:additionaldata] = options[:additionaldata]
    create_parameters[:colleague_id] = options[:colleague_id]  
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'

    self.create(create_parameters)
  end

  def self.log_community_removal(options = {})
    required = [:person_id,:community_id,:oldconnectiontype]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    connector_id = options[:connector_id] || Person.system_id

    create_parameters = {}
    create_parameters[:person_id] = options[:person_id]
    create_parameters[:site] = 'local'
    case options[:oldconnectiontype]
    when 'leader'
      create_parameters[:activitycode] = ( (options[:person_id] == connector_id) ? COMMUNITY_LEFT : COMMUNITY_REMOVEDASLEADER )
    when 'member'
      create_parameters[:activitycode] = ( (options[:person_id] == connector_id) ? COMMUNITY_LEFT : COMMUNITY_REMOVEDASMEMBER )
    when 'invitedleader'
      if((options[:person_id] == connector_id))
        create_parameters[:activitycode] = COMMUNITY_DECLINE_INVITATION      
      else
        return nil
      end
    when 'invitedmember'
      if((options[:person_id] == connector_id))
        create_parameters[:activitycode] = COMMUNITY_DECLINE_INVITATION      
      else
        return nil
      end
    when 'pending'
      create_parameters[:activitycode] = COMMUNITY_REMOVE_PENDING      
    else
      return nil
    end

    create_parameters[:community_id] = options[:community_id]       
    create_parameters[:colleague_id] = connector_id  
    create_parameters[:additionalinfo] = options[:additionalinfo]
    create_parameters[:additionaldata] = options[:additionaldata]
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'

    self.create(create_parameters)
  end

  def self.log_community_connection_change(options = {})
    required = [:person_id,:community_id,:connectiontype,:oldconnectiontype]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    connector_id = options[:connector_id] || Person.system_id

    create_parameters = {}
    create_parameters[:person_id] = options[:person_id]
    create_parameters[:site] = 'local'
    case options[:connectiontype]
    when 'leader'
      case options[:oldconnectiontype]
      when 'invitedleader'
        create_parameters[:activitycode] = ( (options[:person_id] == connector_id) ? COMMUNITY_ACCEPT_INVITATION : COMMUNITY_ADDEDASLEADER )
      else
        create_parameters[:activitycode] = COMMUNITY_ADDEDASLEADER
      end
    when 'member'
      case options[:oldconnectiontype]
      when 'invitedmember'
        create_parameters[:activitycode] = ( (options[:person_id] == connector_id) ? COMMUNITY_ACCEPT_INVITATION : COMMUNITY_ADDEDASMEMBER )
      when 'leader'
        create_parameters[:activitycode] = COMMUNITY_REMOVEDASLEADER        
      else
        create_parameters[:activitycode] = COMMUNITY_ADDEDASMEMBER
      end
    when 'invitedleader'
      create_parameters[:activitycode] = COMMUNITY_INVITEDASLEADER
    when 'invitedmember'
      create_parameters[:activitycode] = COMMUNITY_INVITEDASMEMBER
    else
      return nil
    end

    create_parameters[:community_id] = options[:community_id]       
    create_parameters[:colleague_id] = connector_id  
    create_parameters[:additionalinfo] = options[:additionalinfo]
    create_parameters[:additionaldata] = options[:additionaldata]
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'

    self.create(create_parameters)
  end


  def self.log_community_connection(options = {})
    required = [:person_id,:community_id,:connectiontype]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    connector_id = options[:connector_id] || Person.system_id

    create_parameters = {}
    create_parameters[:person_id] = options[:person_id]
    create_parameters[:site] = 'local'
    case options[:connectiontype]
    when 'leader'
      create_parameters[:activitycode] = ( (options[:person_id] == connector_id) ? COMMUNITY_JOIN : COMMUNITY_ADDEDASLEADER )
    when 'member'
      create_parameters[:activitycode] = ( (options[:person_id] == connector_id) ? COMMUNITY_JOIN : COMMUNITY_ADDEDASMEMBER )
    when 'pending'
      create_parameters[:activitycode] = COMMUNITY_PENDING
    when 'invitedleader'
      create_parameters[:activitycode] = COMMUNITY_INVITEDASLEADER
    when 'invitedmember'
      create_parameters[:activitycode] = COMMUNITY_INVITEDASMEMBER
    else
      return nil
    end
     
    create_parameters[:colleague_id] = connector_id
    create_parameters[:community_id] = options[:community_id]           
    create_parameters[:additionalinfo] = options[:additionalinfo]
    create_parameters[:additionaldata] = options[:additionaldata]
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'

    self.create(create_parameters)
  end


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