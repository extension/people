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
end
