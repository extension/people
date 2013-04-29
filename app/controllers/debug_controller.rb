# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DebugController < ApplicationController
  skip_before_filter :signin_required, :check_hold_status
  before_filter :signin_optional

  def session_information
  end

  def crash
    @fred.boom!
  end
  
end