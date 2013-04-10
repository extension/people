# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class RetiredAccount < ActiveRecord::Base
  serialize :communities
  belongs_to :person
  belongs_to :retiring_colleague, class_name: 'Person'
end