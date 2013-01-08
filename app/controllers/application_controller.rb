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
  helper_method :current_person

end
