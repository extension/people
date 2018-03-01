# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class SignupEmail < ActiveRecord::Base
  attr_accessible :token, :email, :confirmed
  attr_accessible :referer_track,:referer_track_id, :invitation, :invitation_id, :person, :person_id

  validates :email, :presence => true, :email => true, :uniqueness => {:case_sensitive => false}

  before_create :generate_token

  def has_whitelisted_email?
    (self.email =~ /edu$|gov$/i)
  end

  def send_signup_confirmation
   Notification.create(notifiable: self, notification_type: Notification::CONFIRM_SIGNUP)
  end

  def generate_token
    self.token = SecureRandom.hex
  end

  def self.cleanup_signups
    self.where(confirmed: false).where("created_at < ?",Time.now - 14.day).each do |signup_email|
      signup_email.destroy
    end
  end

end
