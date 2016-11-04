#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Site < ActiveRecord::Base
  attr_accessible :label, :database, :dev_database, :uri, :dev_uri, :apptype, :default_role

  has_many :site_roles



  def sync_database
    if(Settings.app_location == 'dev')
      self.dev_database
    else
      self.database
    end
  end

  def proxy_roles
    site_roles.where(permission: SiteRole::PROXY)
  end


end
