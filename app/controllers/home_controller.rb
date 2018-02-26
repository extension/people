# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class HomeController < ApplicationController
  skip_before_filter :signin_required, only: [:help]
  skip_before_filter :check_hold_status, only: [:pending, :help]
  before_filter :signin_optional, only: [:help]
  before_filter :set_referer_track, only: [:index]

  before_filter :set_tab

  def index
    scoped = Person.display_accounts.where('DATE(last_activity_at) >= ?',Date.today - 1.month)
    @active_count = scoped.count
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
