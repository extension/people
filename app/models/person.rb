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
  before_save :check_account_status
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
  has_one :google_account, dependent: :destroy

  belongs_to :invitation
  has_many :activities

  has_many :social_network_connections, dependent: :destroy
  has_many :social_networks, through: :social_network_connections, 
                         select:  "social_network_connections.accountid as accountid, 
                                   social_network_connections.accounturl as accounturl,
                                   social_network_connections.is_public as is_public, 
                                   social_networks.*"  
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
      raise AuthenticationError.new(error_code: Activity::AUTH_INVALID_ID)
    elsif check_person.retired?
      raise AuthenticationError.new(error_code: Activity::AUTH_ACCOUNT_RETIRED, person_id: check_person.id)
    elsif(check_person.password_hash.blank? and check_person.legacy_password.blank?)
      raise AuthenticationError.new(error_code: Activity::AUTH_PASSWORD_EXPIRED, person_id: check_person.id)
    elsif(!check_person.check_password(password))
      raise AuthenticationError.new(error_code: Activity::AUTH_INVALID_PASSWORD, person_id: check_person.id)
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

  def primary_institution
    self.communities.institutions.where(id: self.institution_id).first
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

  # since we return a default string from timezone, this routine
  # will allow us to check for a null/empty value so we can
  # prompt people to come set one.
  def has_time_zone?
    tzinfo_time_zone_string = read_attribute(:time_zone)
    return (!tzinfo_time_zone_string.blank?)
  end

  # override timezone writer/reader
  # returns Eastern by default, use convert=false
  # when you need a timezone string that mysql can handle
  def time_zone(convert=true)
    tzinfo_time_zone_string = read_attribute(:time_zone)
    if(tzinfo_time_zone_string.blank?)
      tzinfo_time_zone_string = DEFAULT_TIMEZONE
    end

    if(convert)
      reverse_mappings = ActiveSupport::TimeZone::MAPPING.invert
      if(reverse_mappings[tzinfo_time_zone_string])
        reverse_mappings[tzinfo_time_zone_string]
      else
        nil
      end
    else
      tzinfo_time_zone_string
    end
  end

  def time_zone=(time_zone_string)
    mappings = ActiveSupport::TimeZone::MAPPING
    if(mappings[time_zone_string])
      write_attribute(:time_zone, mappings[time_zone_string])
    else
      write_attribute(:time_zone, nil)
    end
  end


  def self.cleanup_signup_accounts
    self.where(account_status: STATUS_SIGNUP).where("created_at < ?",Time.now - 14.day).each do |person|
      person.destroy
    end
  end

  def confirm_signup(options = {})
    now = Time.now.utc
   
    if(self.has_whitelisted_email?)
      self.vouched = true 
      self.vouched_by = self.id
      self.vouched_at = now
    end

    # was this person invited? - even if can self-vouch, this will overwrite vouched_by
    if(invitation = self.invitation)
      if(self.has_whitelisted_email? or (invitation.email.downcase == self.email.downcase))
       invitation.accept(self,now)
       self.vouched = true 
       self.vouched_by = invitation.person.id
       self.vouched_at = now
      else
       # what we really should do here is send an email to the person that made the invitation
       # and ask them to vouch for the person with the different email that used the right invitation code
       # but a different, non-whitelisted email.
       invitation.status = Invitation::INVALID_DIFFERENTEMAIL
       invitation.additionaldata = {:invalid_reason => 'invitation email does not match signup email', :signup_email => self.email}
       invitation.save
      end
    end

    # is there an unaccepted invitation with this email address in it? - then let's call it an accepted invitation
    invitation = Invitation.where(email: self.email).where(status: Invitation::PENDING).first
    if(!invitation.nil?)
      invitation.accept(self,now)
      self.vouched = true 
      self.vouched_by = invitation.person.id
      self.vouched_at = now
    end  

    # email settings
    self.emailconfirmed = true
    self.email_event_at = now
    self.account_status = STATUS_OK # will get reset before_save via :check_account_status if not valid

    if(self.save)
      self.clear_token

      # log signup
      if(options[:nolog].nil? or !options[:nolog])
        self.activities.create(activitycode: Activity::SIGNUP, ip_address: options[:ip_address])
      end

      if(self.vouched?)
        # add to institution based on signup.
        if(!self.institution.nil?)
          # TODO community joining routines
          # self.join_community(self.institution)
        end

        Notification.create(:notifytype => Notification::WELCOME, :account => @currentuser, :send_on_create => true)
      else
        self.post_account_review_request(options)
      end

      return true
    else
      return false
    end
  end

  def post_account_review_request(options = {})
    if(self.vouched?)
      return true
    end

    request_options = {}
    request_options['account_review_key'] = Settings.account_review_key
    request_options['idstring'] = self.login
    request_options['email'] = self.email
    request_options['fullname'] = self.fullname
    if (!self.affiliation.blank?)
      request_options['additional_information'] = self.affiliation
    end

    begin
    raw_result = RestClient.post(AppConfig.configtable['account_review_url'],
                             request_options.to_json,
                             :content_type => :json, :accept => :json)
    rescue StandardError => e
      raw_result = e.response
    end
    result = ActiveSupport::JSON.decode(raw_result.gsub(/'/,"\""))
    if(result['success'])
      postresults = {:success => true, :request_id => result['question_id']}
      loginfo = "SUCCESS: #{result['question_id']}"
    else
      postresults = {:success => false, :error => result['message']}
      loginfo = "FAILURE: #{result['message']}"
    end

    if(options[:nolog].nil? or !options[:nolog])
      self.activities.create(activitycode: Activity::REVIEW_REQUEST, ip_address: options[:ip_address], additionalinfo: loginfo, additionaldata: postresults)
    end

    result['success']
  end

  def clear_token
    self.update_column(:token,nil)
  end


  # def join_community_as_leader(community)
  #  # only called for user community creation - so no activity/no notification necessary
  #  self.modify_or_create_communityconnection(community,{:operation => 'add', :connectiontype => 'leader'})
  # end
  
  # def join_community(community,notify=true)
  #  activitycode = Activity::COMMUNITY_JOIN
  #  notificationcode = notify ? Notification.translate_connection_to_code('join') : Notification::NONE
  #  self.modify_or_create_communityconnection(community,{:activitycode => activitycode,:notificationcode => notificationcode, :operation => 'add', :connectiontype => 'member'})
  # end
  
  # def wantstojoin_community(community,notify=true)
  #  activitycode = Activity::COMMUNITY_WANTSTOJOIN
  #  notificationcode = notify ? Notification.translate_connection_to_code('wantstojoin') : Notification::NONE
  #  self.modify_or_create_communityconnection(community,{:activitycode => activitycode, :notificationcode => notificationcode, :operation => 'add', :connectiontype => 'wantstojoin'})
  # end

  #   def modify_or_create_communityconnection(community,options)
  #  connector = options[:connector].nil? ? self : options[:connector]
  #  success = modify_or_create_connection_to_community(community,options)
  #  if(success)
  #   if(options[:activitycode])
  #     Activity.log_activity(:user => self,:creator => connector, :community => community, :activitycode => options[:activitycode], :appname => 'local')
  #   end
    
  #   if(options[:notificationcode] and options[:notificationcode] != Notification::NONE)
  #     Notification.create(:notifytype => options[:notificationcode], :account => self, :creator => connector, :community => community)
  #     # FIXME: user events really shouldn't be based on notificationcodes, but such is life
  #     if(connector != self)
  #      UserEvent.log_event(:etype => UserEvent::COMMUNITY,:user => connector,:description => Notification.userevent(options[:notificationcode],self,community))
  #      UserEvent.log_event(:etype => UserEvent::COMMUNITY,:user => self,:description => Notification.showuserevent(options[:notificationcode],self,connector,community))
  #     else
  #      UserEvent.log_event(:etype => UserEvent::COMMUNITY,:user => self,:description => Notification.userevent(options[:notificationcode],self,community))
  #     end
  #   end
    
  #   if(!options[:no_list_update])
  #     operation = options[:operation]
  #     connectiontype = options[:connectiontype]
  #     community.touch_lists
  #   end
  #  end
  # end

  def create_admin_account
    admin_account = Person.new
    admin_account.attributes = self.attributes
    admin_account.last_name = "#{self.last_name} Admin Account"
    admin_account.login = "#{self.login}-admin"
    admin_account.is_admin = true
    admin_account.email = "#{admin_user.login}@extension.org"
    admin_account.primary_account_id = self.id
    admin_account.password = ''
    admin_account.save
    admin_account
  end

  private

  def check_account_status
    if (!self.retired? and self.account_status != STATUS_SIGNUP)
      if (!self.emailconfirmed?)
        self.account_status = STATUS_CONFIRMEMAIL if (account_status != STATUS_INVALIDEMAIL and account_status != STATUS_INVALIDEMAIL_FROM_SIGNUP)
      elsif (!self.vouched?)
        self.account_status = STATUS_REVIEW
      elsif self.contributor_agreement.nil?
        self.account_status = STATUS_REVIEWAGREEMENT
      elsif not self.contributor_agreement
        self.account_status = STATUS_PARTICIPANT
      else
        self.account_status = STATUS_CONTRIBUTOR
      end
    end  
  end

end