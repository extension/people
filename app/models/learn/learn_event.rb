# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class LearnEvent < ActiveRecord::Base
  # connects to the learn database
  self.establish_connection :learn
  self.table_name='events'

  has_many :presenter_connections, :class_name => "LearnPresenterConnection",foreign_key: 'event_id'
  has_many :presenters, through: :presenter_connections, :source => :learner, :order => 'position'
  has_many :event_activities, :class_name => "LearnEventActivity",foreign_key: 'event_id'
  belongs_to :creator, :class_name => "LearnLearner"
  belongs_to :last_modifier, :class_name => "LearnLearner"

end
