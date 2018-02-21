# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class RefererTrack < ActiveRecord::Base
  attr_accessible :ipaddr, :referer, :expires_at, :user_agent, :load_count

  def self.expired
    where("expires_at < ?",Time.now)
  end

  def self.cleanup_unused_tracks
    used = SignupEmail.pluck(:referer_track_id)
    self.expired.where("id NOT IN (?)",used).each do |rt|
      rt.destroy
    end
  end

end
