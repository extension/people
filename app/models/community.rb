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
    'pending' => "connectiontype = 'pending'",
    'interested' => "connectiontype = 'interest'",
    'interested_list' => "connectiontype IN ('pending',interest','leader')"
  }

           
  CONNECTIONS = {'member' => 'Community Member',
    'leader' => 'Community Leader',
    'wantstojoin' => 'Wants to Join Community',
    'interest' => 'Interested in Community',
    'invited' => 'Community Invitation'}

  belongs_to :creator, :class_name => "Person", :foreign_key => "created_by"
  has_many :community_connections, :dependent => :destroy
  has_many :people, through: :community_connections, 
                    select:  "community_connections.connectiontype as connectiontype, 
                              community_connections.sendnotifications as sendnotifications, 
                              people.*"

  has_many :mailman_lists

  scope :approved, where(entrytype: APPROVED)
  scope :institutions, where(entrytype: INSTITUTION)

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

  def leaders
    connected('leaders')
  end

  def joined
    connected('joined')
  end

  def members
    connected('members')
  end

  def interested
    connected('interested')
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
    if(searchterm.to_i > 0)
      community = self.where(id: searchterm).first
    else
      community = self.where(shortname: searchterm).first
    end

    if(raise_not_found and community.nil?)
      raise ActiveRecord::RecordNotFound
    else
      community
    end
  end





end