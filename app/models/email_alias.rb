# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class EmailAlias < ActiveRecord::Base
  attr_accessible :aliasable, :aliasable_type, :aliasable_id, :alias_type, :mail_alias, :destination

  validates_presence_of :alias_type, :mail_alias, :destination

  belongs_to :aliasable, polymorphic: true
  
  
  # alias_types
  FORWARD         = 1
  CUSTOM_FORWARD  = 2
  GOOGLEAPPS      = 3
  ALIAS           = 4

  # TODO change this in some way
  COMMUNITY_GOOGLEAPPS       = 101
  COMMUNITY_NOWHERE          = 102
  SYSTEM_FORWARD             = 201
  SYSTEM_ALIAS               = 202
  
    
  def self.mail_alias_in_use?(mail_alias,checkobject=nil)
    conditions = "mail_alias = '#{mail_alias}'"
    if(checkobject)
      if(checkobject.is_a?(Community))
        conditions += " AND community_id <> #{checkobject.id}"
      end
    end
    count = EmailAlias.count(:conditions => conditions)
    return (count > 0)
  end
    
    
  
end