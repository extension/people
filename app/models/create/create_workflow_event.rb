# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class CreateWorkflowEvent < ActiveRecord::Base
  self.establish_connection :create
  self.table_name= 'node_workflow_events'
	self.primary_key = 'weid'

  # workflow event_id
  DRAFT = 1
  READY_FOR_REVIEW = 2
  REVIEWED = 3
  READY_FOR_PUBLISH = 4
  PUBLISHED = 5
  UNPUBLISHED = 6
  INACTIVATED = 7
  ACTIVATED = 8
  READY_FOR_COPYEDIT = 9

  REVIEWED_EVENTS = [READY_FOR_REVIEW,REVIEWED,READY_FOR_PUBLISH,READY_FOR_COPYEDIT]

  EVENT_STRINGS = {
    DRAFT => 'moved to draft',
    READY_FOR_REVIEW => 'marked ready for review',
    REVIEWED => 'reviewed',
    READY_FOR_PUBLISH => 'marked ready for publishing',
    PUBLISHED => 'published',
    UNPUBLISHED => 'unpublished',
    INACTIVATED => 'marked inactive',
    ACTIVATED => 'marked as active',
    READY_FOR_COPYEDIT => 'marked ready for copy editing'
  }

  def created_at
    Time.at(self.created).to_datetime
  end

end
