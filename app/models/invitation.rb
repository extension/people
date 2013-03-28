# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Invitation < ActiveRecord::Base
  include MarkupScrubber

  ## attributes
  serialize :invitedcommunities
  attr_accessible :email, :invitedcommunities, :message

  ## validations
  validates :email, :presence => true, :email => true, :uniqueness => {:message => "has already been invited" }

  ## associations
  belongs_to :person
  
  ## scopes
  scope :pending, where(accepted: false)

  def self.remove_expired_invitations
    self.where("created_at < ?",Time.now - 14.day).each do |invitation|
      invitation.destroy
    end
  end

  # override invitedcommunities= to remove blanks
  def invitedcommunities=(list)
    return if(!list.is_a?(Array))
    write_attribute(:invitedcommunities, list.reject(&:blank?))
  end

  # override message= to scrub
  def message=(text)
    write_attribute(:message, self.html_to_pretty_text(text,{encode_special_chars: false}))
  end

  def invitedcommunities
    list = read_attribute(:invitedcommunities)
    if(list)
      list.map{|id| Community.find_by_id(id)}.compact.uniq
    else
      nil
    end
  end

  

    
  # def accept(acceptingcolleague,accepted_at=Time.now.utc)
  #   self.colleague = acceptingcolleague
  #   self.status = ACCEPTED
  #   self.accepted_at = accepted_at
  #   if(self.save)
  #     UserEvent.log_event(:etype => UserEvent::INVITATION,:user => acceptingcolleague,:description => "accepted invitation from #{self.user.login}")    
  #     Activity.log_activity(:user => acceptingcolleague,:colleague => self.user, :activitycode => Activity::INVITATION_ACCEPTED, :appname => 'local')
  #     Notification.create(:notifytype => Notification::INVITATION_ACCEPTED, :account => self.user, :creator => acceptingcolleague, :additionaldata => {:invitation_id => self.id})
  #   end
    
  #   # check for community invitations
  #   if(!self.additionaldata.nil? and !self.additionaldata[:invitecommunities].nil?)
  #     communityids = self.additionaldata[:invitecommunities]
  #     communityids.each do |invitedcommunity_id|
  #       if(community = Community.find(invitedcommunity_id.to_i))
  #         community.invite_user(self.colleague,false,self.user)
  #       end
  #     end
  #   end
  # end
  
  # def resend(resentby)
  #   self.generate_token
  #   self.resent_count += 1
  #   self.resent_at = Time.now.utc
  #   if(self.additionaldata.nil?)
  #     self.additionaldata = {:resentby => [resentby.id]}
  #   elsif(self.additionaldata[:resentby].nil?)
  #     self.additionaldata.merge!({:resentby => [resentby.id]})
  #   else
  #     self.additionaldata[:resentby] << resentby.id 
  #   end
  #   self.save
    
  #   # notification
  #   notificationdata = {:invitation_email => self.email, :invitation_token => self.token }
  #   if(!self.resendmessage.blank?)
  #     notificationdata[:invitation_message] = Hpricot(self.resendmessage).to_plain_text
  #   end
    
  #   if(!self.message.blank?)
  #     if(notificationdata[:invitation_message].blank?)
  #       notificationdata[:invitation_message] = Hpricot(self.message).to_plain_text
  #     else
  #       notificationdata[:invitation_message] += "\nOriginal Message:\n--------------------\n" + Hpricot(self.message).to_plain_text
  #     end
  #   end
    
  #   Notification.create(:notifytype => Notification::INVITATION_TO_EXTENSIONID, :account => resentby, :additionaldata => notificationdata)
  #   UserEvent.log_event(:etype => UserEvent::INVITATION,:user => self.user,:description => "resent invitation to #{self.email}")
  #   Activity.log_activity(:user => self.user,:activitycode => Activity::INVITATION, :appname => 'local',:additionaldata => {:invitedemail => self.email, :invitation_id => self.id})                  
    
  # end

  # def sendinvitation
  #   notificationdata = {:invitation_email => self.email, :invitation_token => self.token }
  #   if(!self.message.blank?)
  #     notificationdata[:invitation_message] = Hpricot(self.message).to_plain_text
  #   end
  #   Notification.create(:notifytype => Notification::INVITATION_TO_EXTENSIONID, :account => self.user, :additionaldata => notificationdata)
  #   UserEvent.log_event(:etype => UserEvent::INVITATION,:user => self.user,:description => "sent invitation to #{self.email}")
  #   Activity.log_activity(:user => self.user,:activitycode => Activity::INVITATION, :appname => 'local',:additionaldata => {:invitedemail => self.email, :invitation_id => self.id})                  
  # end
    
  # protected
  
  # def generate_token
  #   randval = rand
  #   self.token = Digest::SHA1.hexdigest(AppConfig.configtable['sessionsecret']+self.email+randval.to_s)
  # end
  


    
end