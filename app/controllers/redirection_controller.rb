# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

# This controller handles redirecting old People v1 routes 
# to the new routes inside the application, with any 
# explanations as applicable

# this controller should be removed within a few months
# of the People v2 launch
class RedirectionController < ApplicationController
  skip_before_filter :signin_required, :check_hold_status, only: [:reset]

  def password
    return redirect_to(password_person_url(current_person), :status => :moved_permanently)
  end

  def my_profile
    return redirect_to(person_url(current_person), :status => :moved_permanently)
  end

  def reset
  end

  def confirm
  end


end