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
  
end