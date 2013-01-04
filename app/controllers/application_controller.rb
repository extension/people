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
  helper_method :current_person
  before_filter :signin_required


  def set_current_person(person)
    if(person.blank?)
      @current_person = nil
      reset_session
    else
      @current_person = person
      session[:person_id] = person.id
    end
  end

  def current_person
    if(!@current_person)
      if(session[:person_id])
        @current_person = Person.find_by_id(session[:person_id])
      end
    end
    @current_person
  end

  # move to the last url stored by store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session[:return_to].nil?
      redirect_to default
    else
      redirect_to session[:return_to]
      session[:return_to] = nil
    end
  end

end
