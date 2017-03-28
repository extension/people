# === COPYRIGHT:
# Copyright (c) North Carolina State University
# === LICENSE:
# see LICENSE file
module AccountsHelper

  def signin_prompt_string
    if(session[:last_opierequest].present? and trust_root = session[:last_opierequest].trust_root)
      begin
        loginuri = URI.parse(trust_root)
        if(!loginuri.host.nil?)
          return "Please Sign in for #{loginuri.host}"
        end
      rescue StandardError
        # just rescue
      end
    end

    # here? return default
    return 'Please Sign in'
  end


  def primary_institution_name_for_person(person, niltext = 'not specified')
    if(institution = person.primary_institution)
      institution.name
    else
      niltext.html_safe
    end
  end

  def space_the_final_frontier
    '&nbsp;'.html_safe
  end

  def explain_pending_status(account_status)
    case account_status
    when Person::STATUS_REVIEW
      explanation = "<p>Your account is pending review. #{link_to('Learn more about account reviews',accounts_review_path)}</p>"
    when Person::STATUS_SIGNUP
      explanation = "<h4>You need to confirm your email address.</h4> <p>#{link_to('Learn how',accounts_pending_confirmation_path, class: 'btn btn-default btn-primary')}</p>"
    when Person::STATUS_CONFIRM_EMAIL
      explanation = "<p>You need to confirm your email address. #{link_to('Learn more about email confirmation',accounts_pending_confirmation_path)}</p>"
    when Person::STATUS_TOU_HALT
      explanation = "<p>You have not yet accepted the eXtension Terms of Use.  #TODO - Link</p>"
    when Person::STATUS_CONTRIBUTOR
      # just for debugging - should never see in normal operation
      explanation = "<p>Your current account status is: <span class='label label-info'>Person</span></p>"
     when Person::STATUS_TOU_PENDING
      # just for debugging - should never see in normal operation
      explanation = "<p>Your current account status is: <span class='label label-info'>Terms of Use Acceptance Pending</span></p>"
    else
      explanation = "<p>Unknown account status.</p>"
    end
    return explanation.html_safe
  end

end
