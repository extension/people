#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class SiteRole < ActiveRecord::Base
  attr_accessible :permissable_id, :permissable_type, :site, :permissable, :site_id, :permission

  belongs_to :site
  belongs_to :permissable, polymorphic: true

  # global roles
  ADMINISTRATOR = 1
  EDITOR        = 2
  WRITER        = 3
  READER        = 4

end
