# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class SentEmail < ActiveRecord::Base
  attr_accessible :person, :person_id, :email, :notification, :notification_id, :open_count, :markup

  before_create :generate_hashvalue

  belongs_to :person
  belongs_to :notification


  def generate_hashvalue
    randval = rand
    self.hashvalue = Digest::SHA1.hexdigest(Settings.session_token+self.person_id.to_s+randval.to_s)
  end

  def self.clear_out_old_records
    record_count = self.where("created_at < ?",Time.now - Settings.cleanup_months.months).count
    self.delete_all(["created_at < ?",Time.now - Settings.cleanup_months.months])
    record_count
  end
end
