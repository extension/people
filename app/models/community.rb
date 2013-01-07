# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Community < ActiveRecord::Base
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


  CONNECTION_CONDITIONS = {
    'joined'  => "connectiontype IN ('member','leader')",
    'members' => "connectiontype = 'member'",
    'leaders' => "connectiontype = 'leader'",
    'invited' => "connectiontype = 'invited'",
    'wantstojoin' => "connectiontype = 'wantstojoin'",
    'interested' => "connectiontype = 'interest'",
    'interested_list' => "connectiontype IN ('wantstojoin',interest','leader')"
  }

           
  CONNECTIONS = {'member' => 'Community Member',
    'leader' => 'Community Leader',
    'wantstojoin' => 'Wants to Join Community',
    'interest' => 'Interested in Community',
    'invited' => 'Community Invitation'}


  has_many :community_connections, :dependent => :destroy

  has_many :people, through: :community_connections, 
                    select:  "community_connections.connectiontype as connectiontype, 
                              community_connections.sendnotifications as sendnotifications, 
                              people.*"

  scope :approved, where(entrytype: APPROVED)

  def connected(connection)
    if(CONNECTION_CONDITIONS[connection])
      self.people.validaccounts.where(CONNECTION_CONDITIONS[connection])
    else
      self.people.where(0)
    end
  end

  def joined
    connected('joined')
  end

  def entrytype_to_s
    if !ENTRYTYPE_LABELS[self.entrytype].nil?
      I18n.translate("communities.entrytypes.#{ENTRYTYPE_LABELS[self.entrytype]}")     
    else
      I18n.translate("communities.entrytypes.unknown")     
    end
  end
  
  def memberfilter_to_s
    if !MEMBERFILTER_LABELS[self.memberfilter].nil?
      I18n.translate("communities.memberfilters.#{MEMBERFILTER_LABELS[self.memberfilter]}")     
    else
      I18n.translate("communities.memberfilters.unknown")     
    end
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





end