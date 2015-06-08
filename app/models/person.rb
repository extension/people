#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

require 'bcrypt'
class Person < ActiveRecord::Base
  include BCrypt
  include CacheTools
  include MarkupScrubber
  serialize :password_reset
  serialize :admin_flags
  attr_accessor :password, :current_password, :password_confirmation, :interest_tags

  attr_accessible :first_name, :last_name, :email, :title, :phone, :time_zone, :affiliation, :involvement, :biography
  attr_accessible :password, :interest_tags
  attr_accessible :position_id, :position, :location_id, :location, :county_id, :county, :institution_id, :institution
  attr_accessible :invitation, :invitation_id
  attr_accessible :last_account_reminder, :password_reset, :google_apps_email, :email_forward


  auto_strip_attributes :first_name, :last_name, :email, :title, :affiliation, :squish => true

  ## constants
  DEFAULT_TIMEZONE = 'America/New_York'
  SYSTEMS_USERS = [1,2,3,4,5,6,7,8]
  RESTRICTED_ACCOUNTS = [116955]

  # Systems accounts used in app
  MASTER_ACCOUNT = 1
  MIRROR_ACCOUNT = 2
  MODERATOR_ACCOUNT = 7


  # account status
  STATUS_CONTRIBUTOR = 42
  STATUS_REVIEW = 1
  STATUS_CONFIRM_EMAIL = 2
  STATUS_REVIEWAGREEMENT = 3
  STATUS_PARTICIPANT = 4
  STATUS_RETIRED = 5
  STATUS_INVALIDEMAIL = 6
  STATUS_SIGNUP = 7
  STATUS_INVALIDEMAIL_FROM_SIGNUP = 8

  STATUS_OK = 100

  #

  ## validations
  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :idstring, :presence => true, :uniqueness => {:case_sensitive => false}
  validates :email, :presence => true, :email => true, :uniqueness => {:case_sensitive => false}
  validates :password, :length => { :in => 8..40 }, :presence => true, :on => :create
  validates :involvement, :presence => true, :on => :create
  validate :check_idstring_emailalias_conflicts
  validate :check_for_prior_rename, :on => :update

  ## filters
  before_create :set_hashed_password
  before_save :check_account_status
  before_validation :set_idstring

  after_create :create_or_update_forwarding_email_alias
  after_update :create_or_update_forwarding_email_alias
  after_update :synchronize_accounts
  after_update :update_google_account
  after_update :create_rename_alias
  after_save   :update_nonforwarding_email_aliases

  ## associations
  belongs_to :county
  belongs_to :location
  belongs_to :position
  belongs_to :institution, class_name: 'Community'
  belongs_to :vouching_colleague, class_name: 'Person', foreign_key: 'vouched_by'
  has_one :retired_account

  has_many :community_connections, dependent: :destroy
  has_many :communities, through: :community_connections,
                         select:  "community_connections.connectiontype as connectiontype,
                                   community_connections.sendnotifications as sendnotifications,
                                   communities.*"

  has_many :email_aliases, as: :aliasable
  has_one :google_account, dependent: :destroy
  has_one :share_account, dependent: :destroy
  belongs_to :primary_account, class_name: 'Person'


  belongs_to :invitation
  has_many :activities
  has_many :auth_approvals
  has_many :profile_public_settings, dependent: :destroy
  has_many :social_network_connections, dependent: :destroy
  has_many :social_networks, through: :social_network_connections,
                         select:  "social_network_connections.id as connection_id,
                                   social_network_connections.custom_network_name as custom_network_name,
                                   social_network_connections.accountid as accountid,
                                   social_network_connections.accounturl as accounturl,
                                   social_network_connections.is_public as is_public,
                                   social_networks.*"

  has_many :account_syncs
  has_many :person_interests
  has_many :interests, through: :person_interests

  ## scopes
  scope :retired, -> {where(retired: true)}
  scope :validaccounts, where("retired = #{false} and vouched = #{true}")
  scope :pendingreview, where("retired = #{false} and vouched = #{false} and account_status != #{STATUS_SIGNUP} && email_confirmed = #{true}")
  scope :not_system, where("people.id NOT IN(#{SYSTEMS_USERS.join(',')})")
  scope :display_accounts, validaccounts.not_system
  scope :inactive, lambda{ where('DATE(last_activity_at) < ?',Date.today - Settings.months_for_inactive_flag.months) }
  scope :active, lambda{ where('DATE(last_activity_at) >= ?',Date.today - Settings.months_for_inactive_flag.months) }
  scope :reminder_pool, lambda{ display_accounts.inactive.where('(last_account_reminder IS NULL or last_account_reminder <= ?)',Time.now.utc - Settings.months_for_inactive_flag.months).limit(Settings.inactive_limit) }


  # duplicated from darmok
  # TODO - sanity check this
  scope :patternsearch, lambda {|searchterm|
    # remove any leading * to avoid borking mysql
    # remove any '\' characters because it's WAAAAY too close to the return key
    # strip '+' characters because it's causing a repitition search error
    # strip parens '()' to keep it from messing up mysql query
    sanitizedsearchterm = searchterm.gsub(/\\/,'').gsub(/^\*/,'$').gsub(/\+/,'').gsub(/\(/,'').gsub(/\)/,'').strip

    if sanitizedsearchterm == ''
      return nil
    end

    # in the format wordone wordtwo?
    words = sanitizedsearchterm.split(%r{\s*,\s*|\s+})
    if(words.length > 1)
      findvalues = {
       :firstword => words[0],
       :secondword => words[1]
      }
      conditions = ["((first_name rlike :firstword AND last_name rlike :secondword) OR (first_name rlike :secondword AND last_name rlike :firstword))",findvalues]
    elsif(sanitizedsearchterm.cast_to_i != 0)
      # special case of an id search - needed in admin/colleague searches
      conditions = ["id = #{sanitizedsearchterm.cast_to_i}"]
    else
      findvalues = {
       :findlogin => sanitizedsearchterm,
       :findemail => sanitizedsearchterm,
       :findfirst => sanitizedsearchterm,
       :findlast => sanitizedsearchterm
      }
      conditions = ["(email rlike :findemail OR idstring rlike :findlogin OR first_name rlike :findfirst OR last_name rlike :findlast)",findvalues]
    end
    {:conditions => conditions}
  }

  # runs as validation
  def check_idstring_emailalias_conflicts
    if self.new_record?
      if(existing_alias = EmailAlias.where(mail_alias: self.idstring).first)
        # this message will obviously need to change if people can pick their own id again
        errors.add(:base, "An error has occurred creating your account. Please use the 'Contact Us' link and contact us for assistance.")
      end
    elsif(self.idstring_changed?)
      if(existing_alias = EmailAlias.where(mail_alias: self.idstring).first)
        if(existing_alias.aliasable_type != 'Person')
          errors.add(:idstring, "That eXtensionID idstring is already in use by a group")
        elsif(existing_alias.aliasable_id != self.id)
          errors.add(:idstring, "That eXtensionID idstring is already in use by a colleague or existing email alias")
        end
      end
    end
  end

  # runs as validation
  def check_for_prior_rename
    if(self.idstring_changed?)
      if(existing_alias = self.email_aliases.renames.where(mail_alias: self.idstring).first)
        errors.add(:idstring, "That eXtensionID idstring has already been used. Renames can not be reverted.")
      end
    end
  end


  def change_idstring_to(newidstring)
    self.idstring = newidstring
    return self.save
  end

  def openid_url
    "#{Settings.openid_host}/#{self.idstring}"
  end


  def self.filtered_by(browse_filter)
    with_scope do
      base_scope = select('DISTINCT people.id, people.*')
      if(browse_filter  && !browse_filter.is_all? && settings = browse_filter.settings)
        BrowseFilter::KNOWN_KEYS.each do |filter_key|
          if(settings[filter_key])
            case filter_key
            when 'communities'
              base_scope = base_scope.joins(:communities).where("communities.id IN (#{settings[filter_key].join(',')})").where(Community::CONNECTION_CONDITIONS['joined'])
            when 'locations'
              base_scope = base_scope.where("people.location_id IN (#{settings[filter_key].join(',')})")
            when 'positions'
              base_scope = base_scope.where("people.position_id IN (#{settings[filter_key].join(',')})")
            when 'social_networks'
              base_scope = base_scope.joins(:social_networks).where("social_networks.id IN (#{settings[filter_key].join(',')})")
            when 'interests'
              base_scope = base_scope.joins(:interests).where("interests.id IN (#{settings[filter_key].join(',')})")
            end
          end
        end
      end
      base_scope
    end
  end

  def self.find_by_email_or_idstring_or_id(id,raise_not_found = true)

    if(id.cast_to_i > 0)
      person = self.find_by_id(id)
    elsif(id =~ %r{@})
      person = self.find_by_email(id)
    # does the id contain a least one alpha? let's search by idstring
    elsif(id =~ %r{[[:alpha:]]?})
      person = self.find_by_idstring(id)
    end

    if(!person)
      if(raise_not_found)
        raise ActiveRecord::RecordNotFound
      else
        return nil
      end
    end

    person
  end

  def send_account_reminder
    Notification.create(notifiable: self, notification_type: Notification::ACCOUNT_REMINDER)
  end


  def is_signup?
    self.account_status == STATUS_SIGNUP
  end

  def pendingreview?
    (!self.vouched? && !self.retired? && !self.is_signup? && self.email_confirmed?)
  end

  def validaccount?
    if(self.retired? or !self.vouched? or self.is_signup?)
      return false
    else
      return true
    end
  end



  def signin_allowed?
    if self.retired?
      return false
    elsif SYSTEMS_USERS.include?(self.id)
      return false
    else
      return true
    end
  end

  def activity_allowed?
    if(!self.vouched?)
      return false
    else # status checks
      case self.account_status
      when STATUS_CONTRIBUTOR
        return true
      when STATUS_PARTICIPANT
        return true
      when STATUS_REVIEWAGREEMENT
        return true
      else
        return false
      end
    end
  end

  def is_inactive?
    (self.last_activity_at.nil? or self.last_activity_at  < (Time.zone.now - Settings.months_for_inactive_flag.months))
  end

  def expire_password(set_google_random = true)
    if(set_google_random)
      self.password_hash = nil
      self.legacy_password = nil
      self.password_reset = SecureRandom.hex(16)
      self.save
    else
      self.update_column(:password_hash,nil)
      self.update_column(:legacy_password,nil)
    end
  end

  def set_hashed_password(options = {})
    if(!@password.blank?)
      self.password_hash = Password.create(@password)
      self.password_reset = @password
      if(options[:save])
        self.save!
      end
    else
      return false
    end
  end

  def clear_password_reset
    self.update_column(:password_reset, nil)
  end

  def password_reset
    information = read_attribute(:password_reset)
    if(information.blank? or !information[:iv] or !information[:encrypted_data])
      return nil
    end

    sha256 = Digest::SHA2.new(256)
    aes = OpenSSL::Cipher.new("AES-256-CFB")
    key = sha256.digest("#{self.password_hash}::#{Settings.session_token}")
    aes.decrypt
    aes.key = key
    aes.iv = information[:iv]
    decrypted_data_string = aes.update(information[:encrypted_data]) + aes.final
    decrypted_data = YAML.load(decrypted_data_string)
    if(!decrypted_data.is_a?(Hash) or !decrypted_data[:password])
      return nil
    else
      return decrypted_data[:password]
    end
  end


  def password_reset=(clear_password_string)
    data = {password: Digest::SHA1.hexdigest(clear_password_string)}
    data_string = data.to_yaml
    sha256 = Digest::SHA2.new(256)
    aes = OpenSSL::Cipher.new("AES-256-CFB")
    iv = aes.random_iv
    key = sha256.digest("#{self.password_hash}::#{Settings.session_token}")
    aes.encrypt
    aes.key = key
    aes.iv = iv
    encrypted_data = aes.update(data_string) + aes.final
    write_attribute(:password_reset, {iv: iv, encrypted_data: encrypted_data})
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
    if(/^(http|https):\/\/people.extension.org\/([a-zA-Z]+[a-zA-Z0-9]+)$/ =~ idstring)
      $2
    elsif(/^people.extension.org\/([a-zA-Z]+[a-zA-Z0-9]+)$/ =~ idstring)
      $1
    else
      nil
    end
  end

  def self.check_idstring_for_extensionorg(idstring)
    if(%r{(\w+)\@extension\.org$} =~ idstring)
      $1
    else
      nil
    end
  end


  def self.authenticate(idstring,password)
    idstring.strip!
    if(checkid = check_idstring_for_openid(idstring))
      check_person = self.where(idstring: checkid).first
    elsif(checkid = check_idstring_for_extensionorg(idstring))
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
    self.communities.where("connectiontype IN ('member','leader')").order(:name)
  end

  def invite_communities
    invite_communities = []
    self.connected_communities.each do |c|
      if(c.connectiontype == 'member')
        invite_communities << c if c.memberfilter == Community::OPEN
      elsif(c.connectiontype == 'leader')
        invite_communities << c
      end
    end
    invite_communities
  end

  def is_community_leader?(community)
    self.connection_with_community(community) == 'leader'
  end

  def is_extensionstaff?
    is_community_member?(Community.find(Community::EXTENSION_STAFF))
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

  def is_community_member?(community)
    ['leader','member'].include?(self.connection_with_community(community))
  end

  def connection_with_community(community)
    if(community = self.connected_community(community))
      community.connectiontype
    else
      'none'
    end
  end

  def connected_community(community)
    self.communities.where(id: community.id).first
  end

  def community_connection(community)
    self.community_connections.where(community_id: community.id).first
  end

  def connection_with_community_expanded(community)
    connection = self.connection_with_community(community)
    case connection
    when 'invitedleader'
      locale_key = (community.is_institution? ? 'invitedleader_institution' : 'invitedleader')
    when 'leader'
      locale_key = (community.is_institution? ? 'institutional_team' : 'leader')
    else
      locale_key = connection
    end
    I18n.translate("communities.connections.#{locale_key}")
  end

  def primary_institution
    self.communities.institutions.where(id: self.institution_id).first
  end

  def send_signup_confirmation
   Notification.create(notifiable: self, notification_type: Notification::CONFIRM_SIGNUP)
  end

  # override email_forward to return something on null
  def email_forward
    if(self.email =~ /extension\.org$/i)
      if(self.google_apps_email?)
        "#{self.idstring}@apps.extension.org"
      elsif(forwarding_address = read_attribute(:email_forward))
        forwarding_address
      else
        EmailAlias::NOWHERE_LOCATION
      end
    else
      self.email
    end
  end

  def resend_confirmation
    Notification.create(:notification_type => Notification::CONFIRM_EMAIL, :notifiable => self)
  end


  def check_profile_changes(options = {})
    # institution check
    if(self.previous_changes.keys.include?('institution_id'))
      if(self.institution_id.blank?)
        if(institution = Community.find_by_id(self.previous_changes['institution_id'].first))
          self.remove_from_community(institution,options.merge({connector_id: options[:colleague_id]}))
        end
      elsif(self.communities.institutions.connected_as('joined').include?(self.institution))
        # already connected, do nothing
      else
        self.connect_to_community(self.institution,'member',options.merge({connector_id: options[:colleague_id]}))
      end
    end

    if(self.previous_changes.keys.include?('email'))
      self.previous_email = self.previous_changes['email'][0]
      self.email_confirmed = false
      self.email_confirmed_at = nil
      if(self.account_status != STATUS_SIGNUP)
        self.account_status = STATUS_CONFIRM_EMAIL
      end
      if(self.save)
        Activity.log_activity(options.merge({person_id: self.id,
                                            activitycode: Activity::EMAIL_CHANGE,
                                            additionalinfo: "changed to #{self.email} from #{self.previous_email}",
                                            colleague_id: options[:colleague_id],
                                            additionaldata: {from: self.previous_email, to: self.email}}))
        Notification.create(:notification_type => Notification::CONFIRM_EMAIL, :notifiable => self)
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def confirm_email(options = {})
    self.email_confirmed = true
    self.email_confirmed_at = Time.zone.now
    self.account_status = STATUS_OK

    if(!self.vouched? and self.has_whitelisted_email?)
      self.vouched = true
      self.vouched_by = self.id
      self.vouched_at = Time.now.utc
    end

    if(self.save)
      Activity.log_activity(person_id: self.id, activitycode: Activity::CONFIRMED_EMAIL, additionalinfo: self.email, ip_address: options[:ip_address])
      return true
    else
      return false
    end
  end

  def current_forwarding_email_alias
    self.email_aliases.forwards.first
  end

  def create_rename_alias
    if(changes.keys.include?('idstring'))
      previous_idstring = changes['idstring'][0]
      self.email_aliases.create({mail_alias: previous_idstring, destination: self.idstring, alias_type: EmailAlias::RENAME_ALIAS, disabled: !self.validaccount?})
    end
    true
  end

  def create_or_update_forwarding_email_alias
    if(cfea = current_forwarding_email_alias)
      # if the email changed and it's not confirmed yet, do nothing
      if(self.changes.keys.include?('email') and !self.email_confirmed?)
        # do nothing
      else
        cfea.update_attributes({mail_alias: self.idstring, destination: self.email_forward, disabled: !self.validaccount?})
      end
    else
      self.email_aliases.create({mail_alias: self.idstring, destination: self.email_forward, alias_type: EmailAlias::FORWARD, disabled: !self.validaccount?})
    end
    true
  end

  def update_nonforwarding_email_aliases
    self.email_aliases.notforwards.update_all(disabled: !self.validaccount?,destination: self.idstring)
    true
  end

  def synchronize_accounts
    if(Settings.sync_accounts)
      if((self.validaccount? or self.retired?) and !self.is_systems_account?)
        if(as = self.account_syncs.create({is_rename: self.changes.keys.include?('idstring')}))
          as.queue_update
        end
      end
    end
    true
  end

  def self.system_id
    1
  end

  def self.system_account
    find(self.system_id)
  end

  def is_system_account?
   return (self.id == 1)
  end

  def is_systems_account?
    SYSTEMS_USERS.include?(self.id)
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

  def phone=(phone_number_string)
    if(!phone_number_string.blank?)
      write_attribute(:phone, phone_number_string.to_s.gsub(/[^0-9]/, ''))
    else
      write_attribute(:phone, nil)
    end
  end

  # attr_writer override for response to scrub html
  def biography=(description)
    write_attribute(:biography, self.cleanup_html(description))
  end

  # attr_writer override for response to scrub html
  def involvement=(description)
    write_attribute(:involvement, self.cleanup_html(description))
  end

  def interest_tags=(list)
    list_array = list.split(',').map{|i| i.strip}.sort
    id_list = []
    list_array.each do |t|
      if(t.cast_to_i > 0)
        id_list << t.cast_to_i
      else
        id_list << Interest.find_or_create_by_name(t).id
      end
    end

    id_list.uniq!

    if(id_list.sort != interests.map(&:id).sort)
      attribute_will_change!('interest_tags')
      self.interest_ids=id_list
    end
    interest_tags
  end

  def interest_tags
    self.interests.map(&:name)
  end

  def self.cleanup_signup_accounts
    self.where(account_status: STATUS_SIGNUP).where("created_at < ?",Time.now - 14.day).each do |person|
      person.destroy
    end
  end

  # goes through and retires all accounts that have been ignored in review for the last 14 days
  #
  # @param [String] retired_reason Retiring reason
  def self.cleanup_pending_accounts(retired_reason = 'No one vouched for the account within 14 days')
    the_system = Person.system_account
    self.pendingreview.where("email_confirmed_at < ?",Time.now - 14.day).each do |person|
      person.retire(colleague: the_system, explanation: retired_reason, ip_address: '127.0.0.1')
    end
  end

  def self.expire_dormant_account_passwords(set_google_random = true)
    self.not_system.inactive.where('legacy_password is NOT NULL or password_hash IS NOT NULL').each do |p|
      p.expire_password(set_google_random)
    end
  end


  def self.expire_retired_account_passwords
    retire_pool = RetiredAccount.includes(:person).where('retired_accounts.created_at <= ?',Time.now.utc - 1.week).where('people.legacy_password is NOT NULL or people.password_hash IS NOT NULL').map(&:person)
    retire_pool.each do |p|
      # already retired, so we aren't going to bother
      # with the google password
      p.expire_password(false)
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
      invitation.accept(self,now,options)
      self.vouched = true
      self.vouched_by = invitation.person.id
      self.vouched_at = now
    elsif(invitation = Invitation.where(email: self.email).pending.first)
      # is there an unaccepted invitation with this email address in it? - then let's call it an accepted invitation
      invitation.accept(self,now,options)
      self.vouched = true
      self.vouched_by = invitation.person.id
      self.vouched_at = now
    end

    # email settings
    self.email_confirmed = true
    self.email_confirmed_at = now
    self.account_status = STATUS_OK # will get reset before_save via :check_account_status if not valid

    if(self.save)

      # log signup
      if(options[:nolog].nil? or !options[:nolog])
        Activity.log_activity(person_id: self.id, activitycode: Activity::CONFIRMED_EMAIL, ip_address: options[:ip_address])
      end

      if(self.vouched?)
        # add to institution based on signup.
        if(!self.institution.nil?)
          self.join_community(self.institution, {ip_address: options[:ip_address]})
        end
        Notification.create(:notification_type => Notification::WELCOME, :notifiable => self)
      else
        self.post_account_review_request(options)
      end
      return true
    else
      return false
    end
  end

  def vouch(options = {})
    voucher = options[:voucher]
    self.vouched = true
    self.vouched_by = voucher.id
    self.vouched_at = Time.now.utc


    if(self.save)
      # log vouching
      if(options[:nolog].nil? or !options[:nolog])
        Activity.log_activity(person_id: voucher.id, activitycode: Activity::VOUCHED_FOR, colleague_id: self.id, additionalinfo: options[:explanation], ip_address: options[:ip_address])
      end

      # add to institution based on signup.
      if(!self.institution.nil?)
        self.join_community(self.institution, {ip_address: options[:ip_address]})
      end
      Notification.create(:notification_type => Notification::WELCOME, :notifiable => self)
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
    request_options['idstring'] = self.idstring
    request_options['email'] = self.email
    request_options['fullname'] = self.fullname
    if (!self.involvement.blank?)
      request_options['additional_information'] = self.involvement
    end

    begin
    raw_result = RestClient.post(Settings.account_review_url,
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
      Activity.log_activity(person_id: self.id, activitycode: Activity::REVIEW_REQUEST, ip_address: options[:ip_address], additionalinfo: loginfo, additionaldata: postresults)
    end

    result['success']
  end

  # meant as an api call, sets or modifies the connection without
  # check, but handles setting primary institution
  def connect_to_community(community,connectiontype,options = {})
    if(community.is_institution?)
      # do I have a primary institution connection?  if not, make this primary
      if(self.institution_id.blank?)
        self.update_column(:institution_id,community.id)
      end

      # is this a leadership connection?  if so, add them to the institutional teams community
      if(connectiontype == 'leader')
        self.connect_to_community(Community.find(Community::INSTITUTIONAL_TEAMS_COMMUNITY_ID),'member')
      end
    end

    # existing connection? update, else create
    if(connection = self.community_connections.where(community_id: community.id).first)
      oldconnectiontype = connection.connectiontype
      connection.update_attributes({connectiontype: connectiontype})
      Activity.log_community_connection_change(options.merge({colleague_id: self.id, community_id: community.id, connectiontype: connectiontype, oldconnectiontype: oldconnectiontype}))
      if(options[:nonotify].nil? or !options[:nonotify])
        Notification.create_community_connection_change(options.merge({person_id: self.id, community_id: community.id, connectiontype: connectiontype, oldconnectiontype: oldconnectiontype}))
      end
    else
      self.community_connections.create(community_id: community.id, sendnotifications: (connectiontype == 'leader'), connectiontype: connectiontype)
      Activity.log_community_connection(options.merge({colleague_id: self.id, community_id: community.id, connectiontype: connectiontype}))
      if(options[:nonotify].nil? or !options[:nonotify])
        Notification.create_community_connection(options.merge({person_id: self.id, community_id: community.id, connectiontype: connectiontype}))
      end
    end

    # force cache update
    community.joined_count(force: true)

    # sync members with whatever we sync with
    if(Settings.sync_communities)
      CommunityMemberSync.create_with_pending_check({community: community, person: self})
    end

    if(Settings.sync_google and community.connect_to_google_apps? and ['leader','member'].include?(connectiontype))
      community.update_google_groups(true)
    end
  end

  def remove_from_community(community,options={})
    if(connection = self.community_connections.where(community_id: community.id).first)
      oldconnectiontype = connection.connectiontype

      if(community.is_institution?)
        # do I have a primary institution connection?  if so, and it matches, clear it.
        if(!self.institution_id.blank? and self.institution_id == community.id)
          self.update_column(:institution_id,nil)
        end

        # is this a leadership connection?  if so, add them to the institutional teams community
        if(connection.connectiontype == 'leader')
          self.remove_from_community(Community.find(Community::INSTITUTIONAL_TEAMS_COMMUNITY_ID))
        end
      end

      connection.destroy
      Activity.log_community_removal(options.merge({colleague_id: self.id, community_id: community.id, oldconnectiontype: oldconnectiontype}))
      if(options[:nonotify].nil? or !options[:nonotify])
        Notification.create_community_removal(options.merge({person_id: self.id, community_id: community.id, oldconnectiontype: oldconnectiontype}))
      end
    end
    # force cache update
    community.joined_count(force: true)

    # sync members with whatever we sync with
    if(Settings.sync_communities)
      CommunityMemberSync.create_with_pending_check({community: community, person: self})
    end

    if(Settings.sync_google and community.connect_to_google_apps?)
      community.update_google_groups(true)
    end
  end


  def join_community(community,options={})
    # existing connection?
    if(connection = self.community_connections.where(community_id: community.id).first)
      case connection.connectiontype
      when 'invitedleader'
        self.connect_to_community(community,'leader',options.merge({connector_id: self.id}))
      when 'invitedmember'
        self.connect_to_community(community,'member',options.merge({connector_id: self.id}))
      else
        # no-op
      end
    else
      # moderation check
      case community.memberfilter
      when Community::MODERATED
        self.connect_to_community(community,'pending',options.merge({connector_id: self.id}))
      when Community::INVITATIONONLY
        # no-op
      else
        self.connect_to_community(community,'member',options.merge({connector_id: self.id}))
      end
    end
  end

  def leave_community(community,options={})
    self.remove_from_community(community,options.merge({connector_id: self.id}))
  end


  def create_admin_account
    admin_attributes = self.attributes.dup
    admin_attributes[:id] = nil
    admin_attributes[:password] = SecureRandom.hex(16)
    admin_attributes[:password_reset] = admin_attributes[:password]
    admin_account = Person.new(admin_attributes, :without_protection => true)
    admin_account.last_name = "#{self.last_name} Admin Account"
    admin_account.idstring = "#{self.idstring}-admin"
    admin_account.is_admin = true
    admin_account.email = "#{admin_account.idstring}@extension.org"
    admin_account.primary_account_id = self.id
    admin_account.save
    admin_account.expire_password
    admin_account
  end

  def has_whitelisted_email?
    (self.email =~ /edu$|gov$|mil$/i) ? true : false
  end

  def status_token
    hashids = Hashids.new("#{Settings.token_salt}::#{self.email}")
    hashids.encrypt(self.id,self.account_status)
  end

  def check_token(token)
    hashids = Hashids.new("#{Settings.token_salt}::#{self.email}")
    (token_id,statuscode) = hashids.decrypt(token)
    if(token_id != self.id)
      nil
    else
      statuscode
    end
  end


  def retire(options = {})
    forceretire = options[:force].blank? ? false : options[:force]
    return false if(self.retired? and !forceretire)
    colleague = options[:colleague]
    self.retired = true
    # set is_admin to false
    self.is_admin = false
    self.save

    communities = {}
    self.communities.map{|c| communities[c.id] = c.connectiontype}
    if(!self.retired_account)
      self.create_retired_account(retiring_colleague_id: colleague.id, explanation: options[:explanation], communities: communities)
    end


    # drop community connections
    self.communities.each do |c|
      self.remove_from_community(c,{:nonotify => true, :connector_id => colleague.id, :ip_address => options[:ip_address]})
    end

    # log it
    if(options[:nolog].nil? or !options[:nolog])
      Activity.log_activity(person_id: colleague.id,
                            activitycode: Activity::RETIRE_ACCOUNT,
                            colleague_id: self.id,
                            additionalinfo: options[:explanation],
                            ip_address: options[:ip_address])
    end
    true
  end

  def restore(options={})
    forcerestore = options[:force].blank? ? false : options[:force]
    return false if(!self.retired? and !forcerestore)
    colleague = options[:colleague]
    self.retired = false
    self.save

    if(self.retired_account)
      if(self.retired_account.communities)
        self.retired_account.communities.each do |community_id,connectiontype|
          if(community = Community.find_by_id(community_id))
            self.connect_to_community(community,connectiontype,{:connector_id => colleague.id, :nonotify => true, :ip_address => options[:ip_address]})
          end
        end
      end
      self.retired_account.destroy
    end

    # log it
    if(options[:nolog].nil? or !options[:nolog])
      Activity.log_activity(person_id: colleague.id,
                            activitycode: Activity::ENABLE_ACCOUNT,
                            colleague_id: self.id,
                            additionalinfo: options[:explanation],
                            ip_address: options[:ip_address])
    end

    true
  end


  def reset_token
    randval = rand
    if(!(token = read_attribute(:reset_token)))
      basetoken = Digest::SHA1.hexdigest(Settings.session_token+self.email+Time.now.to_s+randval.to_s)
      token = basetoken[0..6]
      if(someone_else = self.class.where(reset_token: token).first)
        # goes to 11! that should do it, if not, well it'll be the best collision ever.
        token = basetoken[0..10]
      end
      self.update_column(:reset_token,token)
    end
    token
  end

  def clear_reset_token
    self.update_column(:reset_token,nil)
  end



  def public_attributes
    returnvalues = {profile_attributes: {}}
    public_profile_attributes = self.profile_public_settings.is_public.map(&:item)
    if(!public_profile_attributes.empty?)
      returnvalues[:profile_attributes]['fullname'] = self.fullname
      returnvalues[:profile_attributes]['last_name'] = self.last_name
      returnvalues[:profile_attributes]['first_name'] = self.first_name
      public_profile_attributes.each do |profile_attribute|
        case profile_attribute
        when 'position'
          returnvalues[:profile_attributes]['position'] = (self.position.blank? ? nil : self.position.name)
        when 'location'
          returnvalues[:profile_attributes]['location'] = (self.location.blank? ? nil : self.location.name)
        when 'county'
          returnvalues[:profile_attributes]['county'] = (self.county.blank? ? nil : self.county.name)
        when 'institution'
          returnvalues[:profile_attributes]['institution'] = (self.institution.blank? ? nil : self.institution.name)
        when 'interests'
          returnvalues[:profile_attributes]['interests'] = self.interests.blank? ? nil : self.interests.map(&:name)
        else
          returnvalues[:profile_attributes][profile_attribute] = self.send(profile_attribute)
        end
      end
    end
    returnvalues
  end

  def aae_id
    if(id_value = read_attribute(:aae_id))
      id_value
    elsif(id_value = AaeUser.where(darmok_id: self.id).pluck(:id).first)
      self.update_column(:aae_id,id_value)
      id_value
    else
      nil
    end
  end

  def learn_id
    if(id_value = read_attribute(:learn_id))
      id_value
    elsif(id_value = LearnLearner.where(darmok_id: self.id).pluck(:id).first)
      self.update_column(:learn_id,id_value)
      id_value
    else
      nil
    end
  end

  def contributor_agreement_to_s
    if(self.contributor_agreement.nil?)
      'Not reviewed'
    elsif(!self.contributor_agreement)
      'Not accepted'
    else
      'Accepted'
    end
  end

  def self.name_or_nil(item)
    item.nil? ? nil : item.name
  end

  def self.dump_to_csv(filename,options={})
    with_scope do
      CSV.open(filename,'wb') do |csv|
        headers = []
        headers << 'Internal ID'
        headers << 'First Name'
        headers << 'Last Name'
        headers << 'ID String'
        headers << 'Email'
        headers << 'Phone'
        headers << 'Title'
        headers << 'Position'
        headers << 'Institution'
        headers << 'Other affiliation'
        headers << 'Location'
        headers << 'County'
        headers << 'Agreement status'
        headers << 'Account created'
        headers << 'Last active at'
        if(options[:browse_filter])
          filter_objects = options[:browse_filter].settings_to_objects
          if(filter_objects['social_networks'])
            filter_objects['social_networks'].each do |network|
              headers << "#{network.display_name}"
            end
          end
        end
        if(options[:community])
          headers << 'Community connection'
        else
          headers << 'Communities'
        end
        csv << headers
        self.includes(:position, :location, :county, :institution).find_in_batches do |people_group|
          people_group.each do |person|
            row = []
            row << person.id
            row << person.first_name
            row << person.last_name
            row << person.idstring
            row << person.email
            row << person.phone
            row << person.title
            row << self.name_or_nil(person.position)
            row << self.name_or_nil(person.institution)
            row << person.affiliation
            row << self.name_or_nil(person.location)
            row << self.name_or_nil(person.county)
            row << person.contributor_agreement_to_s
            row << (person.created_at ? person.created_at.utc.strftime("%Y-%m-%d %H:%M:%S") : nil)
            row << (person.last_activity_at ? person.last_activity_at.utc.strftime("%Y-%m-%d %H:%M:%S") : nil)
            if(options[:browse_filter])
              filter_objects = options[:browse_filter].settings_to_objects
              if(filter_objects['social_networks'])
                filter_objects['social_networks'].each do |network|
                  if(sn = person.social_networks.where('social_networks.id = ?',network.id).first)
                    row << sn.accountid
                  else
                    row << nil
                  end
                end
              end
            end
            if(options[:community])
              row << person.connection_with_community_expanded(options[:community])
            else
              row << person.communities.where(Community::CONNECTION_CONDITIONS['joined']).map(&:name).join('; ')
            end
            csv << row
          end # person
        end # people group
      end # csv
    end # with_scope
  end

  def update_google_account
    if(self.google_account.blank?)
      if(self.validaccount?)
        self.create_google_account
        self.google_account.queue_account_update
      end
    elsif(self.retired?)
      self.google_account.update_attributes({suspended: true})
      self.google_account.queue_account_update
    else
      self.google_account.update_attributes({suspended: false})
      self.google_account.queue_account_update
    end
    true
  end

  def is_admin_for_application(application)
    if(!self.admin_flags.blank? and self.admin_flags[application])
      true
    else
      false
    end
  end

  def add_admin_flag_for_application(application,save=true)
    self.admin_flags ||= {}
    self.admin_flags[application] = true
    if(save)
      self.save
    end
  end

  def remove_admin_flag_for_application(application,save=true)
    self.admin_flags ||= {}
    self.admin_flags[application] = false
    if(save)
      self.save
    end
  end

  def update_blogs_user

    # note, because blogs.extension.org does not currently
    # match up to user_id = this method intentionally keys
    # off idstring, and provides yet another reason idstrings
    # can't be changed

    if(!blogsuser = BlogsUser.where(user_login: self.idstring).first)
      blogsuser = BlogsUser.create(user_login: self.idstring,
                                   user_pass: Settings.create_password_string,
                                   user_nicename: self.idstring,
                                   user_email: self.email,
                                   user_registered: self.created_at,
                                   display_name: self.fullname)
    else
      blogsuser.update_attributes(user_pass: Settings.create_password_string,
                                  user_nicename: self.idstring,
                                  user_email: self.email,
                                  user_registered: self.created_at,
                                  display_name: self.fullname)
    end

    if(!blogsuser.blogs_openid)
      blogsuser.create_blogs_openid(url: self.openid_url)
    end

    blogsuser
  end

  def add_to_blog(blog_name, role)
    # find the blog first
    if(!blog = BlogsBlog.where(path: "/#{blog_name}/").first)
      return nil
    end

    # insert / update user
    blogsuser = self.update_blogs_user
    blogsuser.add_to_blog(blog, role)
  end


  private

  def check_account_status
    if (!self.retired? and self.account_status != STATUS_SIGNUP)
      if (!self.email_confirmed?)
        self.account_status = STATUS_CONFIRM_EMAIL if (account_status != STATUS_INVALIDEMAIL and account_status != STATUS_INVALIDEMAIL_FROM_SIGNUP)
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
