# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AskDemographic < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='demographics'

  belongs_to :demographic_question, class_name: 'AskDemographicQuestion'

end
