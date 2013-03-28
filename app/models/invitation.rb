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

  ## filters
  before_create :generate_token
  after_create :create_invitation_notification

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

  def accept(acceptingcolleague,accepted_at=Time.now.utc)
    self.accepted_by = acceptingcolleague.id
    self.accepted = true
    self.accepted_at = accepted_at
    if(self.save)
      # Activity.log_activity(:user => acceptingcolleague,:colleague => self.user, :activitycode => Activity::INVITATION_ACCEPTED, :appname => 'local')
      # Notification.create(:notifytype => Notification::INVITATION_ACCEPTED, :account => self.user, :creator => acceptingcolleague, :additionaldata => {:invitation_id => self.id})
    end
    
    # # check for community invitations
    # if(!self.additionaldata.nil? and !self.additionaldata[:invitecommunities].nil?)
    #   communityids = self.additionaldata[:invitecommunities]
    #   communityids.each do |invitedcommunity_id|
    #     if(community = Community.find(invitedcommunity_id.to_i))
    #       community.invite_user(self.colleague,false,self.user)
    #     end
    #   end
    # end
  end
  
  def create_invitation_notification
    Notification.create(:notification_type => Notification::INVITATION_TO_EXTENSIONID, :notifiable => self)
  end
    
  protected
  
  def generate_token
    randval = rand
    self.token = Digest::SHA1.hexdigest(Settings.session_token+self.email+randval.to_s)
  end
  


    
end