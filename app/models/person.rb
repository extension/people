# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AuthenticationError < StandardError
end

class Person < ActiveRecord::Base
  belongs_to :county
  belongs_to :location
  belongs_to :position

  # authentication constants
  AUTH_SUCCESS = 42

  AUTH_UNKNOWN = -1
  AUTH_INVALID_ID = 1
  AUTH_PASSWORD_EXPIRED = 2
  AUTH_INVALID_PASSWORD = 3
  AUTH_ACCOUNT_RETIRED = 4

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
      raise AuthenticationError, AUTH_INVALID_ID
    elsif check_person.retired?
      raise AuthenticationError, AUTH_ACCOUNT_RETIRED
    elsif(check_person.legacy_password.blank?)
      raise AuthenticationError, AUTH_PASSWORD_EXPIRED
    elsif(!check_person.check_password(password))
      raise AuthenticationError, AUTH_INVALID_PASSWORD
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

  def auth_status_check
    if(self.retired?)
      AUTH_ACCOUNT_RETIRED
    elsif(self.legacy_password.blank?)
      AUTH_PASSWORD_EXPIRED
    elsif(self.account_status == STATUS_SIGNUP)
      AUTH_SIGNUP_CONFIRM
    elsif(!self.vouched?)
      case self.account_status
      when STATUS_CONFIRMEMAIL
        AUTH_EMAIL_NOTCONFIRM
      when STATUS_INVALIDEMAIL
        AUTH_INVALID_EMAIL
      when STATUS_INVALIDEMAIL_FROM_SIGNUP
        AUTH_INVALID_EMAIL
      else
        AUTH_ACCOUNT_NOTVOUCHED
      end
    else
      case self.account_status
      when STATUS_CONTRIBUTOR
        AUTH_SUCCESS
      when STATUS_PARTICIPANT
        AUTH_SUCCESS
      when STATUS_REVIEWAGREEMENT
        AUTH_SUCCESS
      when STATUS_REVIEW
        AUTH_ACCOUNT_REVIEW
      when User::STATUS_INVALIDEMAIL
        AUTH_INVALID_EMAIL
      when User::STATUS_INVALIDEMAIL_FROM_SIGNUP
        AUTH_INVALID_EMAIL
      when User::STATUS_CONFIRMEMAIL
        AUTH_EMAIL_NOTCONFIRM
      else
        AUTH_UNKNOWN
      end
    end
  end



end