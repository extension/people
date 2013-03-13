# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class SentEmail < ActiveRecord::Base
  attr_accessible :person, :person_id, :notification_id, :open_count, :markup

  before_create :generate_hashvalue

  belongs_to :person
  
  
  def generate_hashvalue
    randval = rand
    self.hashvalue = Digest::SHA1.hexdigest(Settings.session_token+self.person_id.to_s+randval.to_s)
  end
end
