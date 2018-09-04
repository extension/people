# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Community < ActiveRecord::Base
  include CacheTools
  include MarkupScrubber
  attr_accessible :creator, :created_by
  attr_accessible :name, :description, :location, :location_id, :memberfilter, :connect_to_drupal
  attr_accessible :entrytype, :shortname, :publishing_community, :is_public
  attr_accessible :community_masthead, :community_masthead_cache, :remove_community_masthead
  attr_accessible :blog_id, :primary_contact_id, :membership_level

  mount_uploader :community_masthead, CommunityMastheadUploader
  default_scope where(active: true)

  # hardcoded community ids
  INSTITUTIONAL_TEAMS_COMMUNITY_ID = 80
  EXTENSION_STAFF = 30

  # community types
  APPROVED = 1
  USERCONTRIBUTED = 2
  INSTITUTION = 3

  ENTRYTYPE_LABELS = {
    APPROVED => 'approved',
    USERCONTRIBUTED => 'user_contributed',
    INSTITUTION => 'institution'
  }

  # membership
  OPEN = 1
  MODERATED = 2
  INVITATIONONLY = 3

  MEMBERFILTER_LABELS = {
    OPEN => 'open',
    MODERATED => 'moderated',
    INVITATIONONLY => 'invitation'
  }

  # eXtension insitutitional membership level
  NOT_MEMBER = 0
  BASIC_MEMBER = 1
  PREMIUM_MEMBER = 2

  MEMBERSHIPLEVEL_LABELS = {
    NOT_MEMBER => 'none',
    BASIC_MEMBER => 'basic',
    PREMIUM_MEMBER => 'premium'
  }

  CONNECTION_CONDITIONS = {
    'joined'  => "connectiontype IN ('member','leader')",
    'members' => "connectiontype = 'member'",
    'leaders' => "connectiontype = 'leader'",
    'invited' => "connectiontype IN ('invitedleader','invitedmember')",
    'pending' => "connectiontype = 'pending'"
  }


  CONNECTIONS = {'member' => 'Community Member',
    'leader' => 'Community Leader',
    'pending' => 'Pending Community Review',
    'invitedleader' => 'Community Invitation (Leader)',
    'invitedmember' => 'Community Invitation (Member)'}

  validates :name, :presence => true, :uniqueness => {:case_sensitive => false}
  validates :entrytype, :presence => true

  before_save :set_shortname
  before_save :flag_attributes_for_approved
  after_save :update_google_groups
  after_save :sync_communities

  belongs_to :creator, :class_name => "Person", :foreign_key => "created_by"
  belongs_to :primary_contact, :class_name => "Person", :foreign_key => "primary_contact_id"

  belongs_to :location
  has_many :community_connections, :dependent => :destroy
  has_many :people, through: :community_connections,
                    select:  "community_connections.connectiontype as connectiontype,
                              community_connections.sendnotifications as sendnotifications,
                              people.*"

  has_many :google_groups, :dependent => :destroy
  has_many :activities, :dependent => :destroy
  has_many :community_syncs, :dependent => :destroy
  has_many :institutional_regions, :foreign_key => "institution_id", :dependent => :destroy
  has_many :extension_regions, :through => :institutional_regions
  has_many :site_roles, as: :permissable


  scope :approved, where(entrytype: APPROVED)
  scope :institutions, where(entrytype: INSTITUTION)
  scope :contributed, where(entrytype: USERCONTRIBUTED)

  scope :connected_as, lambda{|connectiontype| where(CONNECTION_CONDITIONS[connectiontype])}

  scope :publishing, ->{where(publishing_community: true)}


  def self.inactive
    unscoped.where(active: false)
  end

  def deactivate
    # remove all connections
    self.people.each do |p|
      p.remove_from_community(self,{connector_id: Person.system_id, nonotify: true})
    end

    self.update_attribute(:active, false)

    # go ahead and remove google groups
    self.google_groups.each do |gg|
      gg.destroy
    end

  end


  def sync_communities
    if(Settings.sync_communities)
      self.community_syncs.create
    end
    true
  end

  # attr_writer override for response to scrub html
  def description=(description)
    write_attribute(:description, self.cleanup_html(description))
  end

  def flag_attributes_for_approved
    if(self.entrytype == APPROVED)
      self.publishing_community = true
      self.connect_to_drupal = true
    end
    true
  end


  def set_shortname
    if(self.shortname.blank?)
      tmpshortname = self.name.gsub(/\W/,'').downcase
    else
      tmpshortname = self.shortname.gsub(/[^\w-]/,'').downcase
    end

    increment = 0
    checkname = tmpshortname

    while(EmailAlias.mail_alias_in_use?(checkname,self.new_record? ? nil : self) or self.class.shortname_in_use?(checkname,self.new_record? ? nil : self))
      increment += 1
      checkname = "#{tmpshortname}_#{increment}"
    end
    self.shortname = checkname
    true
  end

  def self.shortname_in_use?(shortname,checkcommunity = nil)
    count_scope = self.where(shortname: shortname)
    if(checkcommunity)
      count_scope = count_scope.where("id <> #{checkcommunity.id}")
    end
    count_scope.count > 0
  end


  def self.check_shortname(checkname,checkcommunity = nil)
    !(EmailAlias.mail_alias_in_use?(checkname,checkcommunity) or Community.shortname_in_use?(checkname,checkcommunity))
  end

  def update_google_groups(update_members = false)
    if(!self.google_groups.blank?)
      if(update_members)
        self.google_groups.each do |gg|
          gg.queue_members_update
        end
      else
        self.google_groups.each do |gg|
          gg.queue_group_update
        end
      end
    end
    return true
  end

  def create_joined_google_group(use_extension_google_accounts = false)
    if(!(gg = self.joined_google_group))
      # create 'joined' group  - all new groups go to the groups domain
      if(gg = self.google_groups.create(use_extension_google_accounts: use_extension_google_accounts))
        gg.queue_group_update
        gg.queue_members_update
      end
    end
    return gg
  end

  def joined_google_group
    self.google_groups.where(connectiontype: 'joined').first
  end

  def has_google_account_group?
    self.google_groups.where(use_extension_google_accounts: true).count > 0
  end

  def create_leaders_google_group(use_extension_google_accounts = false)
    if(!(gg = self.leaders_google_group))
      if(gg = self.google_groups.create(connectiontype: 'leaders', use_extension_google_accounts: use_extension_google_accounts))
        gg.queue_group_update
        gg.queue_members_update
      end
    end
    return gg
  end

  def leaders_google_group
    self.google_groups.where(connectiontype: 'leaders').first
  end

  def is_institution?
    (self.entrytype == INSTITUTION)
  end

  def connected(connection)
    if(CONNECTION_CONDITIONS[connection])
      self.people.validaccounts.where(CONNECTION_CONDITIONS[connection])
    else
      self.people.where(0)
    end
  end

  def joined_with_public_avatar
    self.people
        .joins(:profile_public_settings)
        .where("profile_public_settings.item = 'avatar'")
        .where("profile_public_settings.is_public = 1")
        .where("people.avatar is NOT NULL")
        .validaccounts.where(CONNECTION_CONDITIONS['joined'])
  end

  def leaders
    connected('leaders')
  end

  def joined
    connected('joined')
  end

  def members
    connected('members')
  end

  def pending
    connected('pending')
  end

  def invited
    connected('invited')
  end

  def entrytype_label
    ENTRYTYPE_LABELS[self.entrytype].present? ? ENTRYTYPE_LABELS[self.entrytype] : 'unknown'
  end

  def entrytype_to_s
    I18n.translate("communities.entrytypes.#{self.entrytype_label}")
  end

  def entrytype_display_label
    self.is_institution? ? 'institution' : 'community'
  end

  def memberfilter_label
    MEMBERFILTER_LABELS[self.memberfilter].present? ? MEMBERFILTER_LABELS[self.memberfilter] : 'unknown'
  end

  def memberfilter_to_s
    I18n.translate("communities.memberfilters.#{self.memberfilter_label}")
  end

  def self.connected_counts(connection)
    if(CONNECTION_CONDITIONS[connection])
      with_scope do
        self.joins(:community_connections).where(CONNECTION_CONDITIONS[connection]).group("#{self.table_name}.id").count('community_connections.id')
      end
    else
      {}
    end
  end

  def self.find_by_shortname_or_id(searchterm,raise_not_found = true)
    if(searchterm.cast_to_i > 0)
      community = self.unscoped.where(id: searchterm).first
    else
      community = self.unscoped.where(shortname: searchterm).first
    end

    if(raise_not_found and community.nil?)
      raise ActiveRecord::RecordNotFound
    else
      community
    end
  end

  def leader_notification_pool
    self.notification_pool.where('community_connections.connectiontype = ?',"leader")
  end

  def notification_pool
    self.people.validaccounts.where("community_connections.sendnotifications = ?",true)
  end


  def self.findcommunity(searchterm)
    sanitizedsearchterm = searchterm.gsub(/\\/,'').gsub(/^\*/,'$').gsub(/\+/,'').gsub(/\(/,'').gsub(/\)/,'').strip
    return nil if sanitizedsearchterm == ''

    # exact match?
    if(community = Community.where(name: sanitizedsearchterm).first)
      return [community]
    end

    # query thrice, first by name, then by shortname, and then by description
    namelist = Community.where("name like ?","%#{sanitizedsearchterm}%").order(:name).all
    shortnamelist = Community.where("shortname like ?","%#{sanitizedsearchterm}%").order(:name).all
    descriptionlist = Community.where("description like ?","%#{sanitizedsearchterm}%").order(:name).all
    returnlist = namelist | shortnamelist | descriptionlist
    returnlist
  end

  def joined_count(cache_options = {})
    cache_key = self.get_cache_key(__method__)
    Rails.cache.fetch(cache_key,cache_options) do
      joined.count
    end
  end

  def add_role_for_site(site,permission)
    if(sr = SiteRole.where(permissable_id: self.id).where(permissable_type: self.class.name).where(site_id: site.id).first)
      sr.update_attribute(:permission,permission)
    else
      self.site_roles.create(site: site, permission: permission)
    end
    # synchronize members
    self.joined.each do |p|
      p.synchronize_accounts
    end
  end


  def remove_role_for_site(site)
    if(sr = SiteRole.where(permissable: self).where(site_id: site.id).first)
      sr.destroy
    end
    # synchronize members
    self.joined.each do |p|
      p.synchronize_accounts
    end
  end

  def membership_level_label
    MEMBERSHIPLEVEL_LABELS[self.membership_level].capitalize
  end


end
