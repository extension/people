# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ApplicationController < ActionController::Base
  include AuthLib

  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'yes','YES','y','Y']
  FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE','no','NO','n','N']


  protect_from_forgery
  has_mobile_fu false
  prepend_before_filter :signin_required
  before_filter :set_time_zone_from_user
  before_filter :update_last_activity
  before_filter :check_hold_status
  helper_method :current_person
  helper_method :allow_next_login_tou_reminder?

  def append_info_to_payload(payload)
    super
    payload[:ip] = request.remote_ip
    payload[:auth_id] = current_person.id if current_person
  end

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

  def allow_next_login_tou_reminder?
    if(current_person.account_status == Person::STATUS_TOU_PENDING)
      return true
    else
      return false
    end
  end

  def set_referer_track
    # ignore bots
    return true if request.bot?

    # ignore StatusCake
    return true if(request.env['HTTP_USER_AGENT'] =~ %r{StatusCake}i)

    if(rtid = cookies.signed[:rt] and referer_track = RefererTrack.not_expired.where(id: rtid).first)
      referer_track.increment!(:load_count)
    else
      expires = 1.day.from_now
      referer_track = RefererTrack.create(ipaddr: request.remote_ip,
                                          referer: request.env["HTTP_REFERER"],
                                          user_agent: request.env['HTTP_USER_AGENT'],
                                          expires_at: expires)

      cookies.signed[:rt] = {
        value: referer_track.id,
        expires: expires
      }
    end
  end


end
