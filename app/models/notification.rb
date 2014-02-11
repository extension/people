# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Notification < ActiveRecord::Base
  ## attributes
  serialize :additionaldata
  serialize :results
  attr_accessible :notifiable, :notifiable_type, :notifiable_id, :notification_type, :delivery_time, :additionaldata, :processed, :results, :process_on_create

  ## validations

  ## filters
  before_create :set_delivery_time
  after_create  :queue_notification

  ## associations
  belongs_to :notifiable, :polymorphic => true


  ## scopes


  ## constants
  ## Notification types

  # individual
  WELCOME                             = 101
  CONFIRM_SIGNUP                      = 102
  RECONFIRM_SIGNUP                    = 103
  CONFIRM_EMAIL                       = 104
  RECONFIRM_EMAIL                     = 105
  ACCOUNT_REMINDER                    = 106

  # colleague profile
  UPDATE_COLLEAGUE_PROFILE            = 111

  # passwords
  PASSWORD_RESET_REQUEST              = 120
  PASSWORD_RESET                      = 121


  # community
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

  # eXtensionID Invitation
  INVITATION_TO_EXTENSIONID           = 400
  INVITATION_ACCEPTED                 = 401

  # Downloads
  COLLEAGUE_DOWNLOAD_AVAILABLE        = 500

  

  def set_delivery_time
    if(self.delivery_time.blank?)
      self.delivery_time = Time.now
    end
  end

  def queue_notification
    if(Settings.redis_enabled and !self.process_on_create?)
      self.class.delay_until(self.delivery_time).delayed_notify(self.id)
    else
      self.notify
    end
  end

  def self.delayed_notify(record_id)
    if(record = find_by_id(record_id))
      record.notify
    end
  end


  def notify
    method_name = self.class.code_to_constant_string(self.notification_type)
    methods = self.class.instance_methods.map{|m| m.to_s}
    if(methods.include?(method_name))
      begin 
        self.send(method_name)
        self.update_attributes({processed: true})
      rescue NotificationError => e
        self.update_attributes({results: "ERROR! #{e.message}"})
      end
    else
      self.update_attributes({results: "ERROR! No method for this notification type"})
    end
  end

  def confirm_signup
    AccountMailer.signup({recipient: self.notifiable, notification: self}).deliver
  end

  def confirm_email
    AccountMailer.confirm({recipient: self.notifiable, notification: self}).deliver
  end

  def password_reset_request
    AccountMailer.password_reset_request({recipient: self.notifiable, notification: self}).deliver
  end

  def password_reset
    AccountMailer.password_reset({recipient: self.notifiable, notification: self}).deliver
  end

  def welcome
    AccountMailer.welcome({recipient: self.notifiable, notification: self}).deliver
  end

  def account_reminder
    AccountMailer.account_reminder({recipient: self.notifiable, notification: self}).deliver
    person = self.notifiable
    person.update_column(:last_account_reminder,Time.now.utc)
    person.update_column(:account_reminders,(person.account_reminders.blank? ? 1 : person.account_reminders + 1))
  end

  def update_colleague_profile
    if(self.additionaldata.blank? or self.additionaldata[:what_changed].blank? or self.additionaldata[:colleague_id].blank?)
      raise NotificationError, 'Missing additionaldata'
    end

    if(!(colleague = Person.find(self.additionaldata[:colleague_id])))
      raise NotificationError, 'Invalid colleague_id'
    end
    AccountMailer.profile_update({recipient: self.notifiable, colleague: colleague, notification: self, what_changed: self.additionaldata[:what_changed]}).deliver
  end

  def community_join
    validate_community_notification_data
    self.notifiable.notification_pool.each do |recipient|
      CommunityMailer.join({recipient: recipient, person: @person, community: self.notifiable, notification: self}).deliver
    end
  end

  def community_pending
    validate_community_notification_data
    community = Community.find(self.notifiable_id)
    community.leader_notification_pool.each do |recipient|
      CommunityMailer.pending({recipient: recipient, person: @person, community: community, notification: self}).deliver
    end  
  end

  def community_left
    validate_community_notification_data    
    self.notifiable.notification_pool.each do |recipient|
      CommunityMailer.leave({recipient: recipient, person: @person, community: self.notifiable, notification: self}).deliver
    end  
  end

  def community_accept_invitation
    validate_community_notification_data    
    self.notifiable.notification_pool.each do |recipient|
      CommunityMailer.accept_invitation({recipient: recipient, person: @person, community: self.notifiable, notification: self}).deliver
    end      
  end

  def community_decline_invitation
    validate_community_notification_data    
    self.notifiable.notification_pool.each do |recipient|
      CommunityMailer.decline_invitation({recipient: recipient, person: @person, community: self.notifiable, notification: self}).deliver
    end     
  end

  def community_remove_pending
    validate_community_notification_data    
    self.notifiable.notification_pool.each do |recipient|
      CommunityMailer.removed({recipient: recipient, person: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'pending'}).deliver
    end

    # person
    CommunityMailer.removed_person({recipient: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'pending'}).deliver

  end

  def community_invitedasleader
    validate_community_notification_data    
    # group
    self.notifiable.notification_pool.each do |recipient|
      CommunityMailer.invited({recipient: recipient, person: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'leader'}).deliver
    end
    # person
    CommunityMailer.invited_person({recipient: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'leader'}).deliver
  end

  def community_invitedasmember
    validate_community_notification_data    
    self.notifiable.notification_pool.each do |recipient|
      CommunityMailer.invited({recipient: recipient, person: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'member'}).deliver
    end
    # person
    CommunityMailer.invited_person({recipient: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'member'}).deliver
  end

  def community_addedasleader
    validate_community_notification_data    
    self.notifiable.notification_pool.each do |recipient|
      CommunityMailer.added({recipient: recipient, person: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'leader'}).deliver
    end
    # person
    CommunityMailer.added_person({recipient: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'leader'}).deliver

  end

  def community_addedasmember
    validate_community_notification_data    
    self.notifiable.notification_pool.each do |recipient|
      CommunityMailer.added({recipient: recipient, person: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'member'}).deliver
    end
    # person
    CommunityMailer.added_person({recipient: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'member'}).deliver

  end

  def community_removedasleader
    validate_community_notification_data    
    self.notifiable.notification_pool.each do |recipient|
      CommunityMailer.removed({recipient: recipient, person: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'leader'}).deliver
    end
    # person
    CommunityMailer.removed_person({recipient: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'leader'}).deliver

  end

  def community_removedasmember
    validate_community_notification_data    
    self.notifiable.notification_pool.each do |recipient|
      CommunityMailer.removed({recipient: recipient, person: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'member'}).deliver
    end  

    # person
    CommunityMailer.removed_person({recipient: @person, community: self.notifiable, notification: self, connector: @connector, connectiontype: 'member'}).deliver

  end

  def community_rescindinvitation
    # no-op because I'm not sure this should
    # trigger a notification
  end


  def validate_community_notification_data
    if(self.additionaldata.blank? or self.additionaldata[:person_id].blank? or self.additionaldata[:connector_id].blank?)
      raise NotificationError, 'Missing additionaldata'
    end

    if(!(@person = Person.find(self.additionaldata[:person_id])))
      raise NotificationError, 'Invalid person_id in additionaldata'
    end

    if(!(@connector = Person.find(self.additionaldata[:connector_id])))
      raise NotificationError, 'Invalid connector_id in additionaldata'
    end
  end    

  def invitation_to_extensionid
    AccountMailer.invitation({invitation: self.notifiable, notification: self}).deliver
  end

  def invitation_accepted
    AccountMailer.invitation_accepted({invitation: self.notifiable, notification: self}).deliver
  end


  def colleague_download_available
    if(self.notifiable.notifylist)
      self.notifiable.notifylist.each do |id|
        if(person = Person.find_by_id(id))
          AccountMailer.colleague_download_available({browse_filter: self.notifiable, notification: self, recipient: person}).deliver
        end
      end
    end
    # clear notify list
    self.notifiable.notifylist = []
    self.notifiable.save
  end

  def self.code_to_constant_string(code)
    constantslist = self.constants
    constantslist.each do |c|
      value = self.const_get(c)
      if(value.is_a?(Fixnum) and code == value)
        return c.to_s.downcase
      end
    end
  
    # if we got here?  return nil
    return nil
  end


  def self.create_community_removal(options = {})
    required = [:person_id,:community_id,:oldconnectiontype]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    connector_id = options[:connector_id] || Person.system_id

    create_parameters = {}
    create_parameters[:notifiable_id] = options[:community_id]
    create_parameters[:notifiable_type] = 'Community'
    create_parameters[:additionaldata] = {person_id: options[:person_id], connector_id: connector_id}

    case options[:oldconnectiontype]
    when 'leader'
      create_parameters[:notification_type] = ( (options[:person_id] == connector_id) ? COMMUNITY_LEFT : COMMUNITY_REMOVEDASLEADER )
    when 'member'
      create_parameters[:notification_type] = ( (options[:person_id] == connector_id) ? COMMUNITY_LEFT : COMMUNITY_REMOVEDASMEMBER )
    when 'invitedleader'
      if((options[:person_id] == connector_id))
        create_parameters[:notification_type] = COMMUNITY_DECLINE_INVITATION      
      else
        return nil
      end
    when 'invitedmember'
      if((options[:person_id] == connector_id))
        create_parameters[:notification_type] = COMMUNITY_DECLINE_INVITATION      
      else
        return nil
      end
    when 'pending'
      create_parameters[:notification_type] = COMMUNITY_REMOVE_PENDING      
    else
      return nil
    end

    self.create(create_parameters)
  end

  def self.create_community_connection_change(options = {})
    required = [:person_id,:community_id,:connectiontype,:oldconnectiontype]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    connector_id = options[:connector_id] || Person.system_id

    create_parameters = {}
    create_parameters[:notifiable_id] = options[:community_id]
    create_parameters[:notifiable_type] = 'Community'
    create_parameters[:additionaldata] = {person_id: options[:person_id], connector_id: connector_id}

    case options[:connectiontype]
    when 'leader'
      case options[:oldconnectiontype]
      when 'invitedleader'
        create_parameters[:notification_type] = ( (options[:person_id] == connector_id) ? COMMUNITY_ACCEPT_INVITATION : COMMUNITY_ADDEDASLEADER )
      else
        create_parameters[:notification_type] = COMMUNITY_ADDEDASLEADER
      end
    when 'member'
      case options[:oldconnectiontype]
      when 'invitedmember'
        create_parameters[:notification_type] = ( (options[:person_id] == connector_id) ? COMMUNITY_ACCEPT_INVITATION : COMMUNITY_ADDEDASMEMBER )
      when 'leader'
        create_parameters[:notification_type] = COMMUNITY_REMOVEDASLEADER        
      else
        create_parameters[:notification_type] = COMMUNITY_ADDEDASMEMBER
      end
    when 'invitedleader'
      create_parameters[:notification_type] = COMMUNITY_INVITEDASLEADER
    when 'invitedmember'
      create_parameters[:notification_type] = COMMUNITY_INVITEDASMEMBER
    else
      return nil
    end


    self.create(create_parameters)
  end


  def self.create_community_connection(options = {})
    required = [:person_id,:community_id,:connectiontype]
    required.each do |required_option|
      if(!options[required_option])
        return nil
      end
    end

    connector_id = options[:connector_id] || Person.system_id

    create_parameters = {}
    create_parameters[:notifiable_id] = options[:community_id]
    create_parameters[:notifiable_type] = 'Community'
    create_parameters[:additionaldata] = {person_id: options[:person_id], connector_id: connector_id}

    case options[:connectiontype]
    when 'leader'
      create_parameters[:notification_type] = ( (options[:person_id] == connector_id) ? COMMUNITY_JOIN : COMMUNITY_ADDEDASLEADER )
    when 'member'
      create_parameters[:notification_type] = ( (options[:person_id] == connector_id) ? COMMUNITY_JOIN : COMMUNITY_ADDEDASMEMBER )
    when 'pending'
      create_parameters[:notification_type] = COMMUNITY_PENDING
    when 'invitedleader'
      create_parameters[:notification_type] = COMMUNITY_INVITEDASLEADER
    when 'invitedmember'
      create_parameters[:notification_type] = COMMUNITY_INVITEDASMEMBER
    else
      return nil
    end
     
    self.create(create_parameters)
  end
  
  
end