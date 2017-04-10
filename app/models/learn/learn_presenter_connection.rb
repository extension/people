# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class LearnPresenterConnection < ActiveRecord::Base
  # connects to the learn database
  self.establish_connection :learn
  self.table_name='presenter_connections'

  belongs_to :event, class_name: 'LearnEvent',foreign_key: 'event_id'
  belongs_to :learner, class_name: 'LearnLearner',foreign_key: 'learner_id'

  scope :event_date_filtered, lambda { |start_date,end_date| includes(:event).where('DATE(events.session_start) >= ? AND DATE(events.session_start) <= ?', start_date, end_date) }


end
