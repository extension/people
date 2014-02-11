# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class RetiredAccount < ActiveRecord::Base
  serialize :communities
  attr_accessible :person_id, :person, :retiring_colleague_id, :retiring_colleague, :explanation, :communities

  belongs_to :person
  belongs_to :retiring_colleague, class_name: 'Person'
end