# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Notification < ActiveRecord::Base
  ## attributes
  serialize :additionaldata
  attr_accessible :notifiable, :notifiable_type, :notifiable_id, :notification_type, :delivery_time, :additionaldata, :processed

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
  CONFIRM_EMAIL_CHANGE                = 106  
  CONFIRM_PASSWORD                    = 107

  # community
  COMMUNITY_PERSON_JOIN               = 201
  COMMUNITY_PERSON_WANTSTOJOIN        = 202
  COMMUNITY_PERSON_LEFT               = 203
  COMMUNITY_PERSON_ACCEPT_INVITATION  = 204
  COMMUNITY_PERSON_DECLINE_INVITATION = 205
  COMMUNITY_PERSON_NOWANTSTOJOIN      = 206
  COMMUNITY_PERSON_INTEREST           = 207
  COMMUNITY_PERSON_NOINTEREST         = 208

  COMMUNITY_LEADER_INVITELEADER       = 301
  COMMUNITY_LEADER_INVITEMEMBER       = 302
  COMMUNITY_LEADER_RESCINDINVITATION  = 303
  COMMUNITY_LEADER_INVITEREMINDER     = 304
  COMMUNITY_LEADER_ADDLEADER          = 305
  COMMUNITY_LEADER_ADDMEMBER          = 306
  COMMUNITY_LEADER_REMOVELEADER       = 307
  COMMUNITY_LEADER_REMOVEMEMBER       = 308
  
  # eXtensionID Invitation
  INVITATION_TO_EXTENSIONID           = 400
  INVITATION_ACCEPTED                 = 401
  

  def set_delivery_time
    if(self.delivery_time.blank?)
      self.delivery_time = 1.minute.from_now
    end
  end

  def queue_notification
    self.delay_until(self.delivery_time).notify
  end

  def notify
    method_name = self.class.code_to_constant_string(self.notification_type)
    methods = self.class.instance_methods.map{|m| m.to_s}
    if(methods.include?(method_name))
      self.send(method_name)
    else
      self.update_attributes({additionaldata: "ERROR! No method for this notification type"})
    end
  end

  def confirm_signup
    AccountMailer.signup({person: self.notifiable}).deliver
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
  
  

  
  
end