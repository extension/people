# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Activity < ActiveRecord::Base
  ## includes

  ## attributes
  serialize :additionaldata

  ## validations

  ## filters

  ## associations
  belongs_to :person
  belongs_to :colleague, :class_name => "Person", :foreign_key => "colleague_id"
  belongs_to :community

  ## scopes

  #scope :community, where("activitycode BETWEEN #{Activity::COMMUNITY_ACTIVITY_START} AND #{Activity::COMMUNITY_ACTIVITY_END}")

  #### activity types
  ADMIN = 1
  PEOPLE = 2
  COMMUNITY = 3

  ## activity codes

  # ADMIN
  ENABLE_ACCOUNT  = 3
  RETIRE_ACCOUNT  = 4
  
  # PEOPLE
  SIGNUP = 101
  INVITATION = 102
  VOUCHED_BY = 103
  VOUCHED_FOR = 104
  UPDATE_PROFILE = 105
  LOGIN_PASSWORD = 106
  LOGIN_OPENID = 107
  INVITATION_ACCEPTED = 109

  # COMMUNITY
  COMMUNITY_CREATE = 200
  COMMUNITY_JOIN = 201
  COMMUNITY_WANTSTOJOIN = 202
  COMMUNITY_LEFT= 203
  COMMUNITY_ACCEPT_INVITATION= 205
  COMMUNITY_DECLINE_INVITATION= 206
  COMMUNITY_NOWANTSTOJOIN = 207
  COMMUNITY_INTEREST = 208
  COMMUNITY_NOINTEREST = 209

  COMMUNITY_INVITEDASLEADER = 210
  COMMUNITY_INVITEDASMEMBER = 211
  COMMUNITY_ADDEDASLEADER = 212
  COMMUNITY_ADDEDASMEMBER = 213
  COMMUNITY_REMOVEDASLEADER = 214
  COMMUNITY_REMOVEDASMEMBER = 215
  COMMUNITY_INVITATIONRESCINDED = 216

  COMMUNITY_UPDATE_INFORMATION = 401
  COMMUNITY_CREATED_LIST = 402




end