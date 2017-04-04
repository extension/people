# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class PublishUser < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :publish
  self.table_name='wp_users'
  self.primary_key = 'ID'

  has_one :publish_openid, foreign_key: 'user_id'
  has_many :publish_usermetas, foreign_key: 'user_id'

  attr_accessible :user_login, :user_pass, :user_nicename, :user_email, :user_registered, :display_name


  def add_to_publish_site(publish_site, role)
    if(role == 'administrator' or role == 'leader')
      capability_string = PHP.serialize({"administrator"=>true})
    else
      capability_string = PHP.serialize({"editor"=>true})
    end

    capability_key = "wp_#{publish_site.blog_id}_capabilities"

    # administrator/editor privs
    if(pum = self.publish_usermetas.where(meta_key: capability_key).first)
      pum.update_attribute(:meta_value,capability_string)
    else
      pum = self.publish_usermetas.create(meta_key: capability_key, meta_value: capability_string)
    end

    # editing
    if(!richpum = self.publish_usermetas.where(meta_key: 'rich_editing').first)
      richpum = self.publish_usermetas.create(meta_key: 'rich_editing', meta_value: 'true')
    end

    pum
  end

  def remove_from_publish_site(publish_site)
    capability_key = "wp_#{publish_site.blog_id}_capabilities"
    if(pum = self.publish_usermetas.where(meta_key: capability_key).first)
      pum.destroy
    end
  end


end
