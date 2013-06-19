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
  prepend_before_filter :signin_required
  before_filter :set_time_zone_from_user
  before_filter :update_last_activity
  before_filter :check_hold_status
  helper_method :current_person


  def update_last_activity
    current_person.update_column(:last_activity_at,Time.now.utc) if current_person
  end

  def set_time_zone_from_user
    if(current_person)
      Time.zone = current_person.time_zone
    else
      Time.zone = Settings.default_display_timezone
    end
    true
  end




end
