# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class PublishSitemeta < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :publish
  self.table_name='wp_sitemeta'
  self.primary_key = 'meta_id'

  attr_accessible :site_id, :meta_key, :meta_value
  PUBLISH_CORE_SITE = 1


  def self.site_administrators(site_id = PUBLISH_CORE_SITE)
    if(bsm = self.where(site_id: site_id).where(meta_key: 'site_admins').first)
      list = PHP.unserialize(bsm.meta_value)
    end
    return list
  end

  def self.add_site_administrator(idstring,site_id = PUBLISH_CORE_SITE)
    if(list = self.site_administrators)
      list << idstring
      list.uniq!
      if(bsm = self.where(site_id: site_id).where(meta_key: 'site_admins').first)
        bsm.update_attribute(:meta_value,PHP.serialize(list))
        return true
      end
    end
    return false
  end

  def self.remove_site_administrator(idstring,site_id = PUBLISH_CORE_SITE)
    if(list = self.site_administrators)
      list.delete_if{|entry| entry == idstring}
      list.uniq!
      if(bsm = self.where(site_id: site_id).where(meta_key: 'site_admins').first)
        bsm.update_attribute(:meta_value,PHP.serialize(list))
        return true
      end
    end
    return false
  end

end
