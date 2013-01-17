# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class MailmanList < ActiveRecord::Base
  belongs_to :community
  has_many :email_aliases


  def mailto
    "#{self.name}@lists.extension.org"
  end
  
end