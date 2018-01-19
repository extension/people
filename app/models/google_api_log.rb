# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class GoogleApiLog < ActiveRecord::Base
  attr_accessible :api_method, :group_key, :user_key, :has_error, :error_class, :error_message

  def self.log_success_request(log_data)
    self.create(log_data.merge({has_error: false}))
  end

  def self.log_error_request(log_data)
    self.create(log_data.merge({has_error: true}))
  end

end
