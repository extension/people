# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class EmailAlias < ActiveRecord::Base
  attr_accessible :aliasable, :aliasable_type, :aliasable_id, :alias_type, :mail_alias, :destination, :disabled, :is_rename

  before_validation  :set_values_from_aliasable
  before_save  :set_values_from_aliasable
  before_save  :check_road_to_nowhere

  validates_presence_of :alias_type, :mail_alias, :destination

  belongs_to :aliasable, polymorphic: true

  # the road to nowhere
  NOWHERE_LOCATION = 'nowhere'

  # alias_types
  FORWARD                   = 1
  ALIAS                     = 2
  GOOGLEAPPS                = 3
  PERSONAL_ALIAS            = 4
  RENAME_ALIAS              = 5
  GOOGLEGROUP               = 6

  MIRROR                    = 200
  SYSTEM_FORWARD            = 201
  SYSTEM_ALIAS              = 202

  scope :active, ->{where(disabled: false)}
  scope :renames, ->{where(alias_type: RENAME_ALIAS)}
  scope :forwards, ->{where(alias_type: FORWARD)}
  scope :system_forwards, ->{where(alias_type: SYSTEM_FORWARD)}
  scope :notforwards, ->{ where("alias_type != #{FORWARD}") }
  scope :aliases, ->{ where("alias_type IN (#{ALIAS},#{MIRROR})") }
  scope :system_aliases, ->{where(alias_type: SYSTEM_ALIAS)}



  def self.mail_alias_in_use?(mail_alias,checkobject=nil)
    count_scope = where(mail_alias: mail_alias)
    if(checkobject)
      if(checkobject.is_a?(Community))
        count_scope = count_scope.where("aliasable_id <> #{checkobject.id} AND aliasable_type = 'Community'")
      end
    end
    count_scope.count > 0
  end

  def mail_alias_address
    "#{self.mail_alias}@extension.org"
  end


  def check_road_to_nowhere
    # override disabled flag if on the road to nowhere
    if(self.destination == NOWHERE_LOCATION)
      self.disabled = true
    end
  end


  def set_values_from_aliasable

    # Person aliasable settings handled in person

    if(self.aliasable.is_a?(GoogleGroup))
      if(self.alias_type == GOOGLEAPPS)
        self.disabled = false
        self.mail_alias = self.aliasable.group_id
        self.destination = "#{self.mail_alias}@#{Settings.googleapps_domain}"
      elsif(self.alias_type == GOOGLEGROUP)
        self.disabled = false
        self.mail_alias = self.aliasable.group_id
        self.destination = "#{self.mail_alias}@#{Settings.googleapps_groups_domain}"
      end
    end
  end

  def self.get_mirror_alias(mail_alias)
    mirror_account = Person.find(Person::MIRROR_ACCOUNT)
    self.where(aliasable_id: mirror_account.id).where(aliasable_type: 'Person').where(mail_alias: mail_alias).first
  end

  def self.mirror_alias_exists?(mail_alias)
    # because jayoung is always typing "alias@extension.org" for this method
    # and creating alias@extension.org@extension.org - just get the LHS if
    # there's an '@'
    check_alias = mail_alias.split('@').first 
    (found = self.get_mirror_alias(check_alias)) ? true : false
  end


  def self.add_mirror_alias(mail_alias)
    if(!(existing = self.get_mirror_alias(mail_alias)))
      mirror_account = Person.find(Person::MIRROR_ACCOUNT)
      self.create(aliasable: mirror_account, destination: mirror_account.idstring, alias_type: SYSTEM_ALIAS, disabled: false, mail_alias: mail_alias)
    else
      existing
    end
  end

  def self.create_external_forward(mail_alias, destination, create_mirror_alias = true)
    returnalias = EmailAlias.create(aliasable_type: 'Person',
                                    aliasable_id: 1,
                                    mail_alias: mail_alias,
                                    destination: destination,
                                    alias_type: SYSTEM_FORWARD)
    if(create_mirror_alias)
      add_mirror_alias(mail_alias)
    end

    returnalias
  end




end
