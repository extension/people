# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AskQuestionEvent < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='question_events'

## includes

## attributes
  serialize :updated_question_values
  serialize :group_logs


## constants
  # date of first QuestionEvent for default dates to avoid hitting db
  FIRST_CONTACT = Date.parse('2006-10-10').to_datetime


  # #'s 3 and 4 were the old marked spam and marked non spam question events from darmok, these were
  # just pulled instead of renumbering all these so to not disturb the other status numbers being pulled over from the other sytem
  ASSIGNED_TO = 1
  RESOLVED = 2
  REACTIVATE = 5
  REJECTED = 6
  NO_ANSWER = 7
  TAG_CHANGE = 8
  WORKING_ON = 9
  EDIT_QUESTION = 10
  PUBLIC_RESPONSE = 11
  REOPEN = 12
  CLOSED = 13
  INTERNAL_COMMENT = 14
  ASSIGNED_TO_GROUP = 15
  CHANGED_GROUP = 16
  CHANGED_LOCATION = 17
  EXPERT_EDIT_QUESTION = 18
  EXPERT_EDIT_RESPONSE = 19
  CHANGED_TO_PUBLIC = 20
  CHANGED_TO_PRIVATE = 21
  CHANGED_FEATURED = 22
  ADDED_TAG = 23
  DELETED_TAG = 24
  PASSED_TO_WRANGLER = 25
  AUTO_ASSIGNED_TO = 26

  EVENT_TO_TEXT_MAPPING = { ASSIGNED_TO => 'assigned to',
                            RESOLVED => 'resolved by',
                            REACTIVATE => 're-activated by',
                            REJECTED => 'rejected by',
                            NO_ANSWER => 'no answer given',
                            TAG_CHANGE => 'tags edited by',
                            WORKING_ON => 'worked on by',
                            EDIT_QUESTION => 'edited question',
                            PUBLIC_RESPONSE => 'public response',
                            REOPEN => 'reopened',
                            CLOSED => 'closed',
                            INTERNAL_COMMENT => 'commented',
                            ASSIGNED_TO_GROUP => 'assigned to group',
                            CHANGED_GROUP => 'group changed',
                            CHANGED_LOCATION => 'location changed',
                            EXPERT_EDIT_QUESTION => 'expert edit of question',
                            EXPERT_EDIT_RESPONSE => 'expert edit of response',
                            CHANGED_TO_PUBLIC => 'changed to public by',
                            CHANGED_TO_PRIVATE => 'changed to private by',
                            CHANGED_FEATURED => 'changed featured by',
                            ADDED_TAG => 'tag added by',
                            DELETED_TAG => 'tag deleted by',
                            PASSED_TO_WRANGLER => 'handed off to',
                            AUTO_ASSIGNED_TO => 'automatically assigned to'
                          }

  HANDLING_EVENTS = [ASSIGNED_TO, PASSED_TO_WRANGLER, ASSIGNED_TO_GROUP, RESOLVED, REJECTED, NO_ANSWER, CLOSED]
  SIGNIFICANT_EVENTS = [REJECTED,PASSED_TO_WRANGLER,NO_ANSWER,EXPERT_EDIT_QUESTION,EXPERT_EDIT_RESPONSE,CHANGED_TO_PUBLIC,CHANGED_TO_PRIVATE]
  UPDATE_LAST_ASSIGNED_AT_EVENTS = [ASSIGNED_TO, ASSIGNED_TO_GROUP, PASSED_TO_WRANGLER]

## validations

## filters

## associations
  belongs_to :question, class_name: 'AskQuestion'
  belongs_to :initiator, :class_name => "AskUser", :foreign_key => "initiated_by_id"
  belongs_to :submitter, :class_name => "AskUser", :foreign_key => "submitter_id"
  belongs_to :recipient, :class_name => "AskUser", :foreign_key => "recipient_id"
  belongs_to :assigned_group, :class_name => "AskGroup", :foreign_key => "recipient_group_id"
  belongs_to :previous_recipient, :class_name => "AskUser", :foreign_key => "previous_recipient_id"
  belongs_to :previous_initiator,  :class_name => "AskUser", :foreign_key => "previous_initiator_id"
  belongs_to :previous_handling_recipient, :class_name => "AskUser", :foreign_key => "previous_handling_recipient_id"
  belongs_to :previous_handling_initiator,  :class_name => "AskUser", :foreign_key => "previous_handling_initiator_id"
  belongs_to :previous_group, class_name: 'AskGroup'
  belongs_to :changed_group, class_name: 'AskGroup'

## scopes
  scope :latest, order("#{self.table_name}.created_at desc")
  scope :handling_events, where("event_state IN (#{HANDLING_EVENTS.join(',')})")
  scope :individual_assignments, where("event_state = ?",ASSIGNED_TO)

  def next_handling_event
    self.question.question_events.handling_events.where("question_events.created_at >= ?",self.created_at).where("question_events.id != ?",self.id).first
  end


end
