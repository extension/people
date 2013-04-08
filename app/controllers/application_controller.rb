# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ApplicationController < ActionController::Base
  include AuthLib
  protect_from_forgery
  has_mobile_fu false
  before_filter :signin_required
  before_filter :update_last_activity
  before_filter :check_hold_status 
  helper_method :current_person


  def update_last_activity
    current_person.touch(:last_activity_at) if current_person
  end

end
