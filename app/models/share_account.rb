# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ShareAccount < ActiveRecord::Base
  attr_accessible :person, :person_id, :username, :password

  before_save  :set_values_from_person

  belongs_to :person

  def set_values_from_person
    self.username = self.person.idstring
  end

end