# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AskUserEvent < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='user_events'

  belongs_to :creator, :class_name => "AskUser", :foreign_key => "created_by"
  belongs_to :user, class_name: 'AskUser', :foreign_key => "user_id"
  after_create :create_user_event_notification

  serialize :updated_user_attributes

  # USER EVENTS
  CHANGED_TAGS = 100
  CHANGED_VACATION_STATUS = 101
  ADDED_LOCATION = 102
  REMOVED_LOCATION = 103
  ADDED_COUNTY = 104
  REMOVED_COUNTY = 105
  ADDED_TAGS = 106
  REMOVED_TAGS = 107
  UPDATED_DESCRIPTION = 108
  UPDATED_PROFILE = 109
  UPDATED_ANSWERING_PREFS = 110

  USER_EVENT_STRINGS = {
    100 => 'changed tags',
    101 => 'changed vacation status',
    102 => 'added expertise location',
    103 => 'removed expertise location',
    104 => 'added expertise county',
    105 => 'removed expertise county',
    106 => 'added expertise tag',
    107 => 'removed expertise tag',
    108 => 'updated description',
    109 => 'updated profile',
    110 => 'updated answering preferences'
  }


end
