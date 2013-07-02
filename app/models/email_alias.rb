# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class EmailAlias < ActiveRecord::Base
  attr_accessible :aliasable, :aliasable_type, :aliasable_id, :alias_type, :mail_alias, :destination

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

  # LEGACY
  SYSTEM_FORWARD             = 201
  SYSTEM_ALIAS               = 202
  
    
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

    
    if(self.aliasable.is_a?(Community))
      if(self.alias_type == GOOGLEAPPS)
        self.disabled = false
        self.mail_alias = self.aliasable.shortname
        self.destination = "#{self.mail_alias}@#{Settings.googleapps_domain}"
      else
        self.disabled = true
        self.mail_alias = self.aliasable.shortname
        self.destination = "noreply"
      end
    end
  end


end