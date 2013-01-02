# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AuthenticationError < StandardError
  attr :error_code
  attr :person_id

  def initialize(options = {})
    @error_code = options[:error_code]
    @person_id = options[:person_id]
  end

end

class Person < ActiveRecord::Base
  belongs_to :county
  belongs_to :location
  belongs_to :position

  # account status
  STATUS_CONTRIBUTOR = 0
  STATUS_REVIEW = 1
  STATUS_CONFIRMEMAIL = 2
  STATUS_REVIEWAGREEMENT = 3
  STATUS_PARTICIPANT = 4
  STATUS_RETIRED = 5
  STATUS_INVALIDEMAIL = 6
  STATUS_SIGNUP = 7
  STATUS_INVALIDEMAIL_FROM_SIGNUP = 8

  STATUS_OK = 100


  def self.check_idstring_for_openid(idstring)
    idstring.strip!
    if(/^(http|https):\/\/people.extension.org\/([a-zA-Z]+[a-zA-Z0-9]+)$/ =~ idstring)
      returnid = $2
    elsif(/^people.extension.org\/([a-zA-Z]+[a-zA-Z0-9]+)$/ =~ idstring)
      returnid = $1
    else
      returnid = nil
    end
    return returnid
  end

  def self.authenticate(idstring,password)
    if(checkid = check_idstring_for_openid(idstring))
      check_person = self.where(idstring: checkid).first
    else
      check_person = self.where("idstring = ? OR email = ?",idstring,idstring).first
    end

    if(check_person.nil?)
      raise AuthenticationError.new(error_code: AuthLog::AUTH_INVALID_ID)
    elsif check_person.retired?
      raise AuthenticationError.new(error_code: AuthLog::AUTH_ACCOUNT_RETIRED, person_id: check_person.id)
    elsif(check_person.legacy_password.blank?)
      raise AuthenticationError.new(error_code: AuthLog::AUTH_PASSWORD_EXPIRED, person_id: check_person.id)
    elsif(!check_person.check_password(password))
      raise AuthenticationError.new(error_code: AuthLog::AUTH_INVALID_PASSWORD, person_id: check_person.id)
    end
    check_person
  end

  def fullname
    return "#{self.first_name} #{self.last_name}"
  end

  def check_password(clear_password_string)
   return false if(clear_password_string.blank?)
   (Digest::SHA1.hexdigest(clear_password_string) == self.legacy_password)
  end

  def signup_affiliation
    ''
  end    


end