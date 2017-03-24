# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class InstitutionalRegion < ActiveRecord::Base
  attr_accessible :extension_region_id, :extension_region, :institution_id, :institution

  belongs_to :extension_region
  belongs_to :institution, class_name: 'Community'

end
