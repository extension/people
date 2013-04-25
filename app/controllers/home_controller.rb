# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class HomeController < ApplicationController
  skip_before_filter :check_hold_status, only: [:pending]
  before_filter :set_tab

  def index
    scoped = Person.display_accounts.where('last_activity_at >= ?',Time.zone.now - 1.month)
    @active_count = scoped.count
    @location_count = scoped.pluck(:location_id).uniq.size   
  end

  def help
  end

  def pending
  end


  # def notice
  #   result = statuscheck(@currentuser)
  #   if(AUTH_SUCCESS == result[:code])
  #     redirect_to(people_welcome_url)
  #   else
  #     @notice = explainauthresult(result[:code])
  #   end
  # end

  private

  def set_tab
    @selected_tab = 'home'
  end



  
end