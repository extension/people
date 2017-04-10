# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AskEvaluationAnswer < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='evaluation_answers'

  ## attributes
  ## constants
  ## validations
  ## filters
  ## associations

  belongs_to :evaluation_question, class_name: 'AskEvaluationQuestion'
  belongs_to :user, class_name: 'AskUser'
  belongs_to :question, class_name: 'AskQuestion'

  ## scopes

end
