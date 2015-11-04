#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Site < ActiveRecord::Base
  attr_accessible :label, :database, :dev_database, :uri, :dev_uri, :apptype

  has_many :site_roles
end
