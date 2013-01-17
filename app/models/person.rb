# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

require 'bcrypt'
class Person < ActiveRecord::Base
  include BCrypt
  attr_accessor :password

  attr_accessible :first_name, :last_name, :email, :title, :phonenumber, :time_zone, :affiliation, :involvement
  attr_accessible :password
  attr_accessible :position_id, :position, :location_id, :location, :county_id, :county, :institution_id, :institution 

  ## validations
  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :idstring, :presence => true, :uniqueness => true 
  validates :email, :presence => true, :email => true, :uniqueness => true
  validates :password, :length => { :in => 8..40 }, :presence => true, :on => :create
  validates :involvement, :presence => true, :on => :create
  
  ## filters
  before_create :set_hashed_password
  before_validation :set_idstring

  after_create :create_email_forward
  after_update :update_email_forward
  after_save :update_email_aliases

  ## associations
  belongs_to :county
  belongs_to :location
  belongs_to :position
  belongs_to :institution # primary institution

  has_many :community_connections, dependent: :destroy
  has_many :communities, through: :community_connections, 
                         select:  "community_connections.connectiontype as connectiontype, 
                                   community_connections.sendnotifications as sendnotifications,
                                   community_connections.connectioncode as connectioncode, 
                                   communities.*"
  
  has_many :email_aliases, as: :aliasable
  
  ## scopes  
  scope :validaccounts, where("retired = #{false} and vouched = #{true}")


  

  ## constants
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

  def validaccount?
    if(self.retired? or !self.vouched? or self.account_status == STATUS_SIGNUP)
      return false
    else
      return true
    end
  end  

  def set_hashed_password(options = {})
    self.password_hash = Password.create(@password)
    if(options[:save])
      self.save!
    end
  end

  # TODO - dump this when or if we can ever let people choose their own idstrings
  def set_idstring(reset=false)
    if(reset or self.idstring.blank?)
      return '' if (self.first_name.blank? or self.last_name.blank?)
      self.base_login_string = (self.first_name + self.last_name[0]).mb_chars.downcase.gsub!(/[^\w]/,'')
    
      # get maximum increment
      if(max = self.class.maximum(:login_increment,:conditions => "base_login_string = '#{self.base_login_string}'"))
        self.login_increment = max + 1
      else
        self.login_increment = 1
      end
    
      # set login
      self.idstring = "#{self.base_login_string}#{self.login_increment.to_s}"
    end
    return true
  end

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
    elsif(check_person.password_hash.blank? and check_person.legacy_password.blank?)
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

    if(!self.password_hash.blank?)
      (Password.new(self.password_hash) == clear_password_string)
    else
      if(Digest::SHA1.hexdigest(clear_password_string) == self.legacy_password)
        self.update_attributes({:password_hash => Password.create(clear_password_string), :legacy_password => nil}, {:without_protection => true})
        true
      else
        false
      end
    end
  end

  def invited_communities
    self.communities.where("connectiontype = 'invited'")
  end

  def pending_communities
    self.communities.where("connectiontype = 'pending'")
  end

  def connected_communities
    self.communities.where("connectiontype IN ('member','leader','interest')")
  end

  def is_community_leader?(community)
    self.connection_with_community(community) == 'leader'
  end

  def can_invite_others_to_community?(community)
    connection = self.connection_with_community(community)
    if(self.is_admin? or (connection == 'leader'))
      true
    elsif(community.memberfilter == Community::OPEN)
      ['member','leader'].include?(connection)
    else
      false
    end
  end

  def can_edit_community?(community)
    self.is_admin? or self.is_community_leader?(community)
  end
  
  def connection_with_community(community)
     if(connection = self.community_connections.where(community_id: community.id).first)
      case connection.connectiontype
      when 'invited'
        case connection.connectioncode
        when CommunityConnection::INVITEDLEADER
          'invitedleader'
        when CommunityConnection::INVITEDMEMBER
          'invitedmember'
        else
          'invited'
        end
      else
        connection.connectiontype
      end
    else
      'none'
    end
  end

  # TODO review how this works
  # https://basecamp.com/1851571/projects/945625-people/todos/26749251-address-primary
  def primary_institution
    self.communities.institutions.where("connectioncode = #{CommunityConnection::PRIMARY_INSTITUTION}").first
  end

  def set_token(options = {})
    if(self.token.blank?)
      randval = rand
      now = Time.now.to_s
      self.token = Digest::SHA1.hexdigest(Settings.session_token+self.email+now+randval.to_s)
      if(options[:save])
        self.save!
      end
    end
  end

  def send_signup_confirmation
   self.set_token(save: true)  
   Notification.create(notifiable: self, notification_type: Notification::CONFIRM_SIGNUP)
  end


  def email_forward
    self.email_aliases.where(mail_alias: self.idstring).first
  end

  def create_email_forward
    self.set_email_forward(googleapps: false)
  end

  def update_email_forward
    current_forward = self.email_forward
    if(current_forward and current_forward.alias_type == EmailAlias::FORWARD)
      current_forward.update_attributes({destination: self.email})
    else
      false
    end
  end

  def set_email_forward(options = {})
    return nil if(options[:destination].blank? and options[:googleapps].blank?)
  
    current_forward = self.email_forward
    if(self.email =~ /extension\.org$/i)
      if(options[:googleapps])
        destination = "#{self.idstring}@apps.extension.org"
        alias_type = EmailAlias::GOOGLEAPPS
      elsif(options[:destination])
        destination = options[:destination]
        alias_type = EmailAlias::CUSTOM_FORWARD        
      else
        return nil
      end
    else
      if(options[:googleapps])
        destination = "#{self.idstring}@apps.extension.org"
        alias_type = EmailAlias::GOOGLEAPPS
      elsif(options[:destination])
        destination = options[:destination]
        alias_type = EmailAlias::CUSTOM_FORWARD        
      else
        destination = self.email
        alias_type = EmailAlias::FORWARD  
      end
    end

    if(current_forward)
      current_forward.update_attributes({destination: destination, alias_type: alias_type})
    else
      self.email_aliases.create({mail_alias: self.idstring, destination: destination, alias_type: alias_type})
    end
  end

  def update_email_aliases
    if(!self.validaccount?)
      self.email_aliases.update_all(disabled: true)
    else
      self.email_aliases.update_all(disabled: false)
    end
  end

  def self.system_id
    1
  end


end