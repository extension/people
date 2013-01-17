# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Notification < ActiveRecord::Base
  ## attributes
  serialize :additionaldata
  attr_accessible :notifiable, :notifiable_type, :notifiable_id, :notification_type, :delivery_time, :additionaldata
  attr_accessible :delayed_job_id, :processed

  ## validations

  ## filters
  before_create :set_delivery_time
 
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

    

  
  
  # # method names for sending notificationmailer mailers for each notification
  # MAILERMETHODS = {}
  # MAILERMETHODS[COMMUNITY_USER_JOIN] = ['community_user']
  # MAILERMETHODS[COMMUNITY_USER_WANTSTOJOIN] = ['community_user']
  # MAILERMETHODS[COMMUNITY_USER_LEFT] = ['community_user']
  # MAILERMETHODS[COMMUNITY_USER_ACCEPT_INVITATION] = ['community_user']
  # MAILERMETHODS[COMMUNITY_USER_DECLINE_INVITATION] = ['community_user']
  # MAILERMETHODS[COMMUNITY_USER_NOWANTSTOJOIN] = ['community_user']
  # MAILERMETHODS[COMMUNITY_USER_INTEREST] = ['community_user']
  # MAILERMETHODS[COMMUNITY_USER_NOINTEREST] = ['community_user']
  # MAILERMETHODS[COMMUNITY_LEADER_INVITELEADER] = ['community_change_notifygroup','community_change_notifyuser']
  # MAILERMETHODS[COMMUNITY_LEADER_INVITEMEMBER] = ['community_change_notifygroup','community_change_notifyuser']
  # MAILERMETHODS[COMMUNITY_LEADER_RESCINDINVITATION] = ['community_change_notifygroup','community_change_notifyuser']
  # MAILERMETHODS[COMMUNITY_LEADER_INVITEREMINDER] = ['community_change_notifygroup','community_change_notifyuser']
  # MAILERMETHODS[COMMUNITY_LEADER_ADDLEADER] = ['community_change_notifygroup','community_change_notifyuser']
  # MAILERMETHODS[COMMUNITY_LEADER_ADDMEMBER] = ['community_change_notifygroup','community_change_notifyuser']
  # MAILERMETHODS[COMMUNITY_LEADER_REMOVELEADER] = ['community_change_notifygroup','community_change_notifyuser']
  # MAILERMETHODS[COMMUNITY_LEADER_REMOVEMEMBER] = ['community_change_notifygroup','community_change_notifyuser']
  # MAILERMETHODS[INVITATION_TO_EXTENSIONID] = ['invitation_to_extensionid']    
  # MAILERMETHODS[INVITATION_ACCEPTED] = ['accepted_extensionid_invitation']    
  # MAILERMETHODS[CONFIRM_EMAIL] = ['confirm_email']      
  # MAILERMETHODS[RECONFIRM_EMAIL] = ['reconfirm_email']    
  # MAILERMETHODS[RECONFIRM_SIGNUP] = ['reconfirm_signup']    
  # MAILERMETHODS[CONFIRM_PASSWORD] = ['confirm_password']    
  # MAILERMETHODS[WELCOME] = ['welcome']    
  # MAILERMETHODS[CONFIRM_EMAIL_CHANGE] = ['confirm_email_change']      
  # MAILERMETHODS[CONFIRM_SIGNUP] = ['confirm_signup']    
  # MAILERMETHODS[LEARN_UPCOMING_SESSION] = ['learn_upcoming_session']   

  
  # # TODO: add description labels that can get strings from the locale tabel describing each 
  

  # belongs_to :account
  # belongs_to :community # for many of the notification types
  # belongs_to :creator, :class_name => "Account", :foreign_key => "created_by"
  # serialize :additionaldata
  
  # before_create :createnotification?
  # after_create :send_now?
  
  # named_scope :tosend, :conditions => {:sent_email => false,:send_error => false}, :order => "created_at ASC"
  # named_scope :people, :conditions => ["notifytype BETWEEN (#{NOTIFICATION_PEOPLE[0]} and #{NOTIFICATION_PEOPLE[1]})"] 
  # named_scope :failed, :conditions => {:send_error => true}, :order => "created_at ASC"
  
  # def send_email
  #   if(MAILERMETHODS[self.notifytype].blank?)
  #     return false
  #   else
  #     MAILERMETHODS[self.notifytype].each do |methodname|
  #       begin 
  #         NotificationMailer.send("deliver_#{methodname}",self)
  #       rescue Exception => exception
  #         if(!self.additionaldata.nil?)
  #           additionaldata = self.additionaldata.merge({:emailerror => exception.message})
  #         else
  #           additionaldata = {:emailerror => exception.message}
  #         end
  #         self.update_attributes({:send_error => true, :additionaldata => additionaldata})            
  #         return false
  #       end
  #     end
  #     self.update_attributes({:sent_email => true, :sent_email_at => Time.now})
  #     return true
  #   end
  # end
  
  # def notifytype_to_s
  #   if(self.notifytype == NONE)
  #     return 'none'
  #   elsif(self.notifytype >= NOTIFICATION_PEOPLE[0] and self.notifytype <= NOTIFICATION_PEOPLE[1])
  #     return 'people'
  #   else
  #     return nil
  #   end
  # end
  
  # def notifytype_to_constant_string
  #   constant_string = Notification.code_to_constant_string(self.notifytype) || 'unknown'
  #   return constant_string
  # end
  
  # def send_now?
  #   if(self.send_on_create?)
  #     self.send_email
  #   end
  # end
  
  # def createnotification?
  #   case self.notifytype
  #   when COMMUNITY_USER_NOINTEREST
  #     return false
  #   when NONE
  #     return false
  #   else
  #     return true
  #   end
  # end
    
  # def self.translate_connection_to_code(connectaction,connectiontype=nil)
  #   case connectaction
  #   when 'removeleader'
  #     COMMUNITY_LEADER_REMOVELEADER
  #   when 'removemember'
  #     COMMUNITY_LEADER_REMOVEMEMBER
  #   when 'addmember'
  #     COMMUNITY_LEADER_ADDMEMBER
  #   when 'addleader'
  #     COMMUNITY_LEADER_ADDLEADER
  #   when 'rescindinvitation'
  #     COMMUNITY_LEADER_RESCINDINVITATION
  #   when 'inviteleader'
  #     COMMUNITY_LEADER_INVITELEADER
  #   when 'invitemember'  
  #     COMMUNITY_LEADER_INVITEMEMBER
  #   when 'leave'
  #     COMMUNITY_USER_LEFT
  #   when 'join'
  #     COMMUNITY_USER_JOIN
  #   when 'nowantstojoin'
  #     COMMUNITY_USER_NOWANTSTOJOIN
  #   when 'wantstojoin'
  #     COMMUNITY_USER_WANTSTOJOIN
  #   when 'interest'
  #     COMMUNITY_USER_INTEREST
  #   when 'nointerest'
  #     COMMUNITY_USER_NOINTEREST
  #   when 'accept'
  #     COMMUNITY_USER_ACCEPT_INVITATION
  #   when 'decline'
  #     COMMUNITY_USER_DECLINE_INVITATION
  #   else
  #     NONE
  #   end
  # end
  
  # def self.clearerrors
  #   errors = find(:all, :conditions => {:send_error => true})
  #   errors.each do |notification|
  #     notification.update_attributes({:send_error => false})
  #   end
  # end
  
  # def self.userevent(notificationcode,account,community)
  #   case notificationcode
  #   when COMMUNITY_LEADER_ADDMEMBER
  #     userevent = "added #{account.login} to #{community.name} membership"
  #   when COMMUNITY_LEADER_ADDLEADER
  #     userevent = "added #{account.login} to #{community.name} leadership"
  #   when COMMUNITY_LEADER_REMOVEMEMBER
  #     userevent = "removed #{account.login} from #{community.name} membership"
  #   when COMMUNITY_LEADER_REMOVELEADER
  #     userevent = "removed #{account.login} from #{community.name} leadership"
  #   when COMMUNITY_LEADER_INVITELEADER
  #     userevent = "invited #{account.login} to #{community.name} leadership"
  #   when COMMUNITY_LEADER_INVITEMEMBER
  #     userevent = "invited #{account.login} to #{community.name} membership"
  #   when COMMUNITY_LEADER_INVITEREMINDER
  #     userevent = "sent an invitation reminder to #{account.login} for the #{community.name} community "      
  #   when COMMUNITY_LEADER_RESCINDINVITATION
  #     userevent = "rescinded invitation for #{account.login} to #{community.name}"
  #   when COMMUNITY_USER_LEFT
  #     userevent = "left #{community.name}"
  #   when COMMUNITY_USER_WANTSTOJOIN
  #     userevent = "wants to join #{community.name}"
  #   when COMMUNITY_USER_NOWANTSTOJOIN
  #     userevent = "no longer wants to join #{community.name}"
  #   when COMMUNITY_USER_INTEREST
  #     userevent = "interested in #{community.name}"
  #   when COMMUNITY_USER_NOINTEREST
  #     userevent = "no longer interested in #{community.name}"
  #   when COMMUNITY_USER_JOIN
  #     userevent = "joined #{community.name}"
  #   when COMMUNITY_USER_ACCEPT_INVITATION
  #     userevent = "accepted invitation to #{community.name}"
  #   when COMMUNITY_USER_ACCEPT_INVITATION
  #     userevent = "declined invitation to #{community.name}"
  #   else
  #     userevent = "Unknown Event"
  #   end
  #   return userevent
  # end
   
  # def self.showuserevent(notificationcode,showuser,byaccount,community)
  #   case notificationcode
  #   when COMMUNITY_LEADER_ADDMEMBER
  #     showuserevent = "added to #{community.name} membership by #{byaccount.login}"
  #   when COMMUNITY_LEADER_ADDLEADER
  #     showuserevent = "added to #{community.name} leadership by #{byaccount.login}"
  #   when COMMUNITY_LEADER_REMOVEMEMBER
  #     showuserevent = "removed from #{community.name} membership by #{byaccount.login}"
  #   when COMMUNITY_LEADER_REMOVELEADER
  #     showuserevent = "removed from #{community.name} leadership by #{byaccount.login}"
  #   when COMMUNITY_LEADER_INVITELEADER
  #     showuserevent = "invited to #{community.name} leadership by #{byaccount.login}"
  #   when COMMUNITY_LEADER_INVITEREMINDER
  #     showuserevent = "reminded of #{community.name} invitation by #{byaccount.login}"
  #   when COMMUNITY_LEADER_INVITEMEMBER
  #     showuserevent = "invited to #{community.name} membership by #{byaccount.login}"
  #   when COMMUNITY_LEADER_RESCINDINVITATION
  #     showuserevent = "invitation to #{community.name} rescinded by #{byaccount.login}"
  #   else
  #     showuserevent = "Unknown event."
  #   end
  #   return showuserevent
  # end


  # def self.code_to_constant_string(code)
  #   constantslist = self.constants
  #   constantslist.each do |c|
  #     value = self.const_get(c)
  #     if(value.is_a?(Fixnum) and code == value)
  #       return c
  #     end
  #   end
  
  #   # if we got here?  return nil
  #   return nil
  # end
  
  

  
  
end