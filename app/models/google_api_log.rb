# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class GoogleApiLog < ActiveRecord::Base
  serialize :errordata
  attr_accessible :api_method, :group_id, :account_id, :resultcode, :errordata


  def self.log_request(log_options)
    self.create(log_options)
  end

end
