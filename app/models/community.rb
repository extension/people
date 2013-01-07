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

  # labels and keys
  ENTRYTYPES = Hash.new
  ENTRYTYPES[APPROVED] = {:locale_key => 'approved', :allowadmincreate => true}
  ENTRYTYPES[USERCONTRIBUTED] = {:locale_key => 'user_contributed', :allowadmincreate => true}
  ENTRYTYPES[INSTITUTION] = {:locale_key => 'institution', :allowadmincreate => true}
  
  # membership
  OPEN = 1
  MODERATED = 2
  INVITATIONONLY = 3
  
  MEMBERFILTERS = {OPEN => 'Open Membership',
    MODERATED => 'Moderated Membership',
    INVITATIONONLY => 'Invitation Only Membership'}
  
           
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


  def joined
    self.people.validaccounts.where("connectiontype IN ('member','leader')")
  end

  def members
    self.people.validaccounts.where("connectiontype = 'member'")
  end

  def leaders
    self.people.validaccounts.where("connectiontype = 'leader'")
  end

  def invited
    self.people.validaccounts.where("connectiontype = 'invited'")
  end

  def interest
    self.people.validaccounts.where("connectiontype = 'interest'")
  end

  def interested
    self.people.validaccounts.where("connectiontype IN ('interest','leader','wantstojoin')")    
  end

  def wantstojoin
    self.people.validaccounts.where("connectiontype = 'wantstojoin'")
  end


end