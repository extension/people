# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class EmailAlias < ActiveRecord::Base
  attr_accessible :aliasable, :aliasable_type, :aliasable_id, :alias_type, :mail_alias, :destination, :disabled

  before_validation  :set_values_from_aliasable
  before_save  :set_values_from_aliasable

  validates_presence_of :alias_type, :mail_alias, :destination

  belongs_to :aliasable, polymorphic: true


  # alias_types
  FORWARD         = 1
  CUSTOM_FORWARD  = 2
  GOOGLEAPPS      = 3
  ALIAS           = 4
  NOWHERE         = 5
  RENAME_ALIAS    = 6

  # LEGACY
  SYSTEM_FORWARD             = 201
  SYSTEM_ALIAS               = 202

  scope :renames, ->{where(alias_type: RENAME_ALIAS)}


  def self.mail_alias_in_use?(mail_alias,checkobject=nil)
    count_scope = where(mail_alias: mail_alias)
    if(checkobject)
      if(checkobject.is_a?(Community))
        count_scope = count_scope.where("aliasable_id <> #{checkobject.id} AND aliasable_type = 'Community'")
      end
    end
    count_scope.count > 0
  end


  def set_values_from_aliasable
    # Person aliasable settings handled in person

    if(self.aliasable.is_a?(GoogleGroup))
      if(self.alias_type == GOOGLEAPPS)
        self.disabled = false
        self.mail_alias = self.aliasable.group_id
        self.destination = "#{self.mail_alias}@#{Settings.googleapps_domain}"
      end
    end
  end

  def self.add_mirror_alias(mail_alias)
    mirror_account = Person.find(Person::MIRROR_ACCOUNT)
    if(!(existing = self.where(aliasable_id: mirror_account.id).where(aliasable_type: 'Person').where(mail_alias: mail_alias).first))
      self.create(aliasable: mirror_account, destination: mirror_account.idstring, alias_type: SYSTEM_ALIAS, disabled: false, mail_alias: mail_alias)
    else
      existing
    end
  end


end
