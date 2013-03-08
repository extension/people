# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class MailerCache < ActiveRecord::Base
  attr_accessible :person, :person_id, :notification_id, :cacheable, :cacheable_id, :cacheable_type, :open_count, :markup

  belongs_to :person
  belongs_to :cacheable, :polymorphic => true
  
  before_create :generate_hashvalue
  
  def generate_hashvalue
    randval = rand
    self.hashvalue = Digest::SHA1.hexdigest(Settings.session_token+self.person_id.to_s+randval.to_s)
  end
end
