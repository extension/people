# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Invitation < ActiveRecord::Base
  include MarkupScrubber

  ## attributes
  serialize :invitedcommunities
  attr_accessible :email, :invitedcommunities, :message

  auto_strip_attributes :email

  ## validations
  validates :email, :presence => true, :email => true, :uniqueness => {:message => "has already been invited", :case_sensitive => false }

  ## filters
  before_create :generate_token
  after_create :create_invitation_notification

  ## associations
  belongs_to :person
  belongs_to :colleague, :class_name => "Person", :foreign_key => "accepted_by"

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
      []
    end
  end

  def accept(acceptingcolleague,accepted_at=Time.now.utc,options = {})
    self.accepted_by = acceptingcolleague.id
    self.accepted = true
    self.accepted_at = accepted_at
    if(self.save)
      Notification.create(:notification_type => Notification::INVITATION_ACCEPTED, :notifiable => self)
      Activity.log_activity(person_id: acceptingcolleague.id,
                            colleague_id: self.person_id,
                            activitycode: Activity::INVITATION_ACCEPTED,
                            additionalinfo: self.email,
                            additionaldata: {'invitation_id' => self.id},
                            ip_address: options[:ip_address])

      # check for community invitations
      self.invitedcommunities.each do |community|
        acceptingcolleague.connect_to_community(community,'invitedmember',{connector_id: self.person_id, ip_address: options[:ip_address]})
      end
    end
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
