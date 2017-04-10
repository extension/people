# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class LearnLearner < ActiveRecord::Base
  # connects to the learn database
  self.establish_connection :learn
  self.table_name='learners'

  has_many :event_activities, class_name: 'LearnEventActivity',foreign_key: 'learner_id'
  has_many :presenter_connections, :class_name => "LearnPresenterConnection",foreign_key: 'learner_id'
  has_many :presented_events, through: :presenter_connections, :source => :event, :order => 'position'

  has_many :created_events, :class_name => "LearnEvent",foreign_key: 'creator_id'

end
