# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ExtensionRegion < ActiveRecord::Base
  attr_accessible :shortname, :label, :association_url

  has_many :institutional_regions
  has_many :institutions, :through => :institutional_regions

end
