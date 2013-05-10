# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ApplicationController < ActionController::Base
  include AuthLib
  require_dependency 'year_week_stats'

  protect_from_forgery
  has_mobile_fu false
  before_filter :signin_required
  before_filter :set_time_zone_from_user
  before_filter :update_last_activity
  before_filter :check_hold_status
  before_filter :check_for_metric 
  before_filter :set_latest_yearweek
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

  def set_latest_yearweek
    @latest_yearweek = Analytic.latest_yearweek
  end

  def check_for_rebuild
    if(rebuild = Rebuild.latest)
      if(rebuild.in_progress?)
        # probably should return 307 instead of 302
        return redirect_to(root_path)
      end
    end
    true
  end

  def check_for_metric
    @metric = params[:metric]
    if(!PageStat.column_names.include?(@metric))
      @metric = 'unique_pageviews'
    end
    true
  end


end
