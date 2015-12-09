# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Activity < ActiveRecord::Base
  ## includes
  include Rails.application.routes.url_helpers
  default_url_options[:host] = Settings.urlwriter_host

  ## attributes
  serialize :additionaldata
  attr_accessible :person, :person_id, :site, :activityclass, :activitycode, :reasoncode,  :additionalinfo, :additionaldata
  attr_accessible :ip_address, :community, :community_id, :colleague_id, :colleague, :is_private

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
  UPDATE_SOCIAL_NETWORKS              = 112


  PASSWORD_RESET_REQUEST              = 120
  PASSWORD_RESET                      = 121

  # TOU ACTIVITY
  TOU_PRESENTED                       = 131
  TOU_NEXT_LOGIN                      = 132
  TOU_HALT                            = 133
  TOU_ACCEPTED                        = 134

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


  ACTIVITY_STRINGS = {
  AUTH_LOCAL_SUCCESS                  => 'auth_local_success',
  AUTH_LOCAL_FAILURE                  => 'auth_local_failure',
  AUTH_REMOTE_SUCCESS                 => 'auth_remote_success',
  SIGNUP                              => 'signup',
  INVITATION                          => 'invitation',
  VOUCHED_FOR                         => 'vouched_for',
  UPDATE_PROFILE                      => 'update_profile',
  EMAIL_CHANGE                        => 'email_change',
  PASSWORD_CHANGE                     => 'password_change',
  CONFIRMED_EMAIL                     => 'confirmed_email',
  INVITATION_ACCEPTED                 => 'invitation_accepted',
  REVIEW_REQUEST                      => 'review_request',
  UPDATE_COLLEAGUE_PROFILE            => 'update_colleague_profile',
  UPDATE_SOCIAL_NETWORKS              => 'update_social_networks',
  PASSWORD_RESET_REQUEST              => 'password_reset_request',
  PASSWORD_RESET                      => 'password_reset',
  COMMUNITY_CREATE                    => 'community_create',
  COMMUNITY_JOIN                      => 'community_join',
  COMMUNITY_PENDING                   => 'community_pending',
  COMMUNITY_LEFT                      => 'community_left',
  COMMUNITY_ACCEPT_INVITATION         => 'community_accept_invitation',
  COMMUNITY_DECLINE_INVITATION        => 'community_decline_invitation',
  COMMUNITY_REMOVE_PENDING            => 'community_remove_pending',
  COMMUNITY_INVITEDASLEADER           => 'community_invitedasleader',
  COMMUNITY_INVITEDASMEMBER           => 'community_invitedasmember',
  COMMUNITY_ADDEDASLEADER             => 'community_addedasleader',
  COMMUNITY_ADDEDASMEMBER             => 'community_addedasmember',
  COMMUNITY_REMOVEDASLEADER           => 'community_removedasleader',
  COMMUNITY_REMOVEDASMEMBER           => 'community_removedasmember',
  COMMUNITY_RESCINDINVITATION         => 'community_rescindinvitation',
  COMMUNITY_UPDATE_INFORMATION        => 'community_update_information',
  COMMUNITY_CREATED_LIST              => 'community_created_list',
  ENABLE_ACCOUNT                      => 'enable_account',
  RETIRE_ACCOUNT                      => 'retire_account',
  TOU_PRESENTED                       => 'tou_presented',
  TOU_NEXT_LOGIN                      => 'tou_next_login',
  TOU_HALT                            => 'tou_halt',
  TOU_ACCEPTED                        => 'tou_accepted'}


  PRIVATE_ACTIVITIES = [AUTH_LOCAL_FAILURE,PASSWORD_RESET_REQUEST,PASSWORD_RESET,PASSWORD_CHANGE]

  ## validations

  ## filters
  before_save :set_activity_class
  before_save :check_privacy_flag
  after_create :queue_slack_notification

  ## associations
  belongs_to :person
  belongs_to :colleague, :class_name => "Person", :foreign_key => "colleague_id"
  belongs_to :community

  ## scopes
  scope :related_to_person, lambda{|person| where("person_id = ? or colleague_id = ?",person.id,person.id)}
  scope :public_activity, lambda{where(is_private: false)}
  scope :community, where("activitycode >= ? and activitycode <= ?",COMMUNITY_RANGE.first, COMMUNITY_RANGE.last)

  def check_privacy_flag
    if(PRIVATE_ACTIVITIES.include?(self.activitycode))
      self.is_private = true
    elsif(self.activitycode == AUTH_REMOTE_SUCCESS and !(self.site =~ %r{\.extension\.org}))
      self.is_private = true
    end
  end

  def activitycode_to_s
    ACTIVITY_STRINGS[self.activitycode] || 'unknown'
  end

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

  def self.log_tou_activity(options = {})
    person = options[:person]
    logger.debug(person.tou_status)
    case person.tou_status
    when Person::TOU_PRESENTED
      activitycode = TOU_PRESENTED
    when Person::TOU_NEXT_LOGIN
      activitycode = TOU_NEXT_LOGIN
    when Person::TOU_HALT
      activitycode = TOU_HALT
    when Person::TOU_ACCEPTED
      activitycode = TOU_ACCEPTED
    else
      return nil
    end

    create_parameters = {}
    create_parameters[:site] = 'local'
    create_parameters[:person_id] = person.id
    create_parameters[:activitycode] = activitycode
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'
    self.create(create_parameters)
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
    if(!options[:community].blank?)
      create_parameters[:community_id] = options[:community].id
    elsif(!options[:community_id].blank?)
      create_parameters[:community_id] = options[:community_id]
    end

    self.create(create_parameters)
  end

  def self.log_community_removal(options = {})
    required = [:colleague_id,:community_id,:oldconnectiontype]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    connector_id = options[:connector_id] || Person.system_id

    create_parameters = {}
    create_parameters[:person_id] = connector_id
    create_parameters[:colleague_id] = options[:colleague_id]
    create_parameters[:site] = 'local'
    case options[:oldconnectiontype]
    when 'leader'
      create_parameters[:activitycode] = ( (options[:colleague_id] == connector_id) ? COMMUNITY_LEFT : COMMUNITY_REMOVEDASLEADER )
    when 'member'
      create_parameters[:activitycode] = ( (options[:colleague_id] == connector_id) ? COMMUNITY_LEFT : COMMUNITY_REMOVEDASMEMBER )
    when 'invitedleader'
      if((options[:colleague_id] == connector_id))
        create_parameters[:activitycode] = COMMUNITY_DECLINE_INVITATION
      else
        return nil
      end
    when 'invitedmember'
      if((options[:colleague_id] == connector_id))
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
    create_parameters[:additionalinfo] = options[:additionalinfo]
    create_parameters[:additionaldata] = options[:additionaldata]
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'

    self.create(create_parameters)
  end

  def self.log_community_connection_change(options = {})
    required = [:colleague_id,:community_id,:connectiontype,:oldconnectiontype]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    connector_id = options[:connector_id] || Person.system_id

    create_parameters = {}
    create_parameters[:person_id] = connector_id
    create_parameters[:colleague_id] = options[:colleague_id]
    create_parameters[:site] = 'local'
    case options[:connectiontype]
    when 'leader'
      case options[:oldconnectiontype]
      when 'invitedleader'
        create_parameters[:activitycode] = ( (options[:colleague_id] == connector_id) ? COMMUNITY_ACCEPT_INVITATION : COMMUNITY_ADDEDASLEADER )
      else
        create_parameters[:activitycode] = COMMUNITY_ADDEDASLEADER
      end
    when 'member'
      case options[:oldconnectiontype]
      when 'invitedmember'
        create_parameters[:activitycode] = ( (options[:colleague_id] == connector_id) ? COMMUNITY_ACCEPT_INVITATION : COMMUNITY_ADDEDASMEMBER )
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
    create_parameters[:additionalinfo] = options[:additionalinfo]
    create_parameters[:additionaldata] = options[:additionaldata]
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'

    self.create(create_parameters)
  end


  def self.log_community_connection(options = {})
    required = [:colleague_id,:community_id,:connectiontype]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    connector_id = options[:connector_id] || Person.system_id

    create_parameters = {}
    create_parameters[:person_id] = connector_id
    create_parameters[:colleague_id] = options[:colleague_id]
    create_parameters[:site] = 'local'
    case options[:connectiontype]
    when 'leader'
      create_parameters[:activitycode] = ( (options[:colleague_id] == connector_id) ? COMMUNITY_JOIN : COMMUNITY_ADDEDASLEADER )
    when 'member'
      create_parameters[:activitycode] = ( (options[:colleague_id] == connector_id) ? COMMUNITY_JOIN : COMMUNITY_ADDEDASMEMBER )
    when 'pending'
      create_parameters[:activitycode] = COMMUNITY_PENDING
    when 'invitedleader'
      create_parameters[:activitycode] = COMMUNITY_INVITEDASLEADER
    when 'invitedmember'
      create_parameters[:activitycode] = COMMUNITY_INVITEDASMEMBER
    else
      return nil
    end

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

  def self.log_remote_auth_success(options = {})
    required = [:person_id,:site]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    create_parameters = {}
    create_parameters[:site] = options[:site]
    create_parameters[:person_id] = options[:person_id]
    create_parameters[:activityclass] = AUTHENTICATION
    create_parameters[:activitycode] = AUTH_REMOTE_SUCCESS
    create_parameters[:ip_address] = options[:ip_address] || 'unknown'
    self.create(create_parameters)

  end


  def self.periodic_activity_by_person_id(options = {})
    returndata = {}
    months = options[:months]
    end_date = options[:end_date]
    maxdate = self.maximum(:created_at).to_date
    if(maxdate < end_date)
      end_date = maxdate
    end
    start_date = end_date - months.months
    persons = self.where("DATE(created_at) >= ?",start_date).where('person_id > 1').pluck('person_id').uniq
    returndata['months'] = months
    returndata['start_date'] = start_date
    returndata['end_date'] = end_date
    returndata['persons'] = persons.size
    persons.each do |person_id|
      returndata[person_id] ||= {}
      base_scope = self.where("DATE(created_at) >= ?",start_date).where('person_id = ?',person_id)
      returndata[person_id]['dates'] = base_scope.pluck('DATE(created_at)').uniq
      returndata[person_id]['days'] = returndata[person_id]['dates'].size
      returndata[person_id]['items'] = base_scope.count('DISTINCT(activitycode)')
      returndata[person_id]['actions'] = base_scope.count('id')
    end
    returndata
  end

  def self.authsummary
    results = []
    returnhash = {}
    with_scope do
      results = where("activitycode IN (#{AUTH_LOCAL_SUCCESS},#{AUTH_REMOTE_SUCCESS})")
                .select("site,max(activities.created_at) as last_login_at,count(activities.id) as login_count")
                .order('max(activities.created_at) DESC').group(:site)
    end
    results.each do |grouped_object|
      returnhash[grouped_object.site] = {:last_login_at => grouped_object.last_login_at, :login_count => grouped_object.login_count}
    end
    returnhash
  end

  def queue_slack_notification
    if(Settings.sidekiq_enabled)
      self.class.delay.delayed_slack_notification(self.id)
    else
      self.slack_notification
    end
  end

  def self.delayed_slack_notification(record_id)
    if(record = find_by_id(record_id))
      record.slack_notification
    end
  end

  def slack_notification
    return false if(self.is_private?)
    post_options = {}
    post_options[:channel] = Settings.activity_slack_channel
    if(Settings.app_location == 'production')
      post_options[:username] = "People Activity Notification"
    else
      post_options[:username] = "[Development] People Activity Notification"
    end

    attachment = { "fallback" => "#{self.activity_string(:nolink => true)}",
    "mrkdwn_in" => ["fields"],
    "fields" => [
      {
        "value" => "#{Slack::Notifier::LinkFormatter.format(ReverseMarkdown.convert(self.activity_string))}",
        "short" => false
      },
    ],
    "color" => "good"
    }
    post_options[:attachment] = attachment
    SlackNotification.post(post_options)
    true
  end

  def activity_string(options = {})

    hide_community_text = options[:hide_community_text] || false
    hide_person_text = options[:hide_person_text] || false
    nolink = options[:nolink] || false

    text_macro_options = {}

    # note space on the end of link - required in string formatting

    if(self.person_id.blank? and self.activitycode == Activity::AUTH_LOCAL_FAILURE)
      # special case of showing additional information for authentication failures
      text_macro_options[:persontext]  = hide_person_text ? '' : "#{self.additionalinfo} (unknown account) "
    else
      text_macro_options[:persontext]  = hide_person_text ? '' : "#{self.link_to_person(self.person,{nolink: nolink})} "
    end

    if(self.activitycode == Activity::AUTH_REMOTE_SUCCESS)
      text_macro_options[:site] =  self.site
    end


    text_macro_options[:communitytext]  = hide_community_text ? 'community' : "#{self.link_to_community(self.community,{nolink: nolink})} community"
    text_macro_options[:colleaguetext] =  "#{self.link_to_person(self.colleague,{nolink: nolink, show_unknown: true})}"

    if(self.activitycode == Activity::INVITATION)
      text_macro_options[:emailaddress] =  self.additionalinfo
    end

    if(self.activitycode == Activity::EMAIL_CHANGE)
      text_macro_options[:current_email] =  (self.person.email || 'unknown')
      text_macro_options[:previous_email] =  (self.person.previous_email || 'unknown')
    end

    I18n.translate("activity.#{self.activitycode_to_s}",text_macro_options).html_safe

  end

  def link_to_person(person,options = {})
    show_unknown = options[:show_unknown] || false
    show_systemuser = options[:show_systemuser] || false
    nolink = options[:nolink] || false

    if person.nil?
      show_unknown ? 'Unknown' : 'System'
    elsif(person.id == 1 and !show_systemuser)
      'System'
    elsif(nolink)
      "#{person.fullname}"
    else
      ActionController::Base.helpers.link_to(person.fullname,person_url(person),class: 'person').html_safe
    end
  end

  def link_to_community(community,options = {})
    nolink = options[:nolink] || false

    if community.nil?
      '[unknown community]'
    elsif(nolink)
      "#{community.name}"
    else
      ActionController::Base.helpers.link_to(community.name,community_url(community)).html_safe
    end
  end

end
