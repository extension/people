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



  def generate_token
    self.token = SecureRandom.urlsafe_base64
  end

end
