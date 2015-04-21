# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class BlogsUser < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :blogs
  self.table_name='wp_users'
  self.primary_key = 'ID'

  has_one :blogs_openid, foreign_key: 'user_id'
  has_many :blogs_usermetas, foreign_key: 'user_id'

  attr_accessible :user_login, :user_pass, :user_nicename, :user_email, :user_registered, :display_name


  def add_to_blog(blogsblog, role)
    if(role == 'administrator')
      capability_string = PHP.serialize({"administrator"=>true})
    else
      capability_string = PHP.serialize({"editor"=>true})
    end

    capability_key = "wp_#{blogsblog.blog_id}_capabilities"

    # administrator/editor privs
    if(bum = self.blogs_usermetas.where(meta_key: capability_key).first)
      bum.update_attribute(:meta_value,capability_string)
    else
      bum = self.blogs_usermetas.create(meta_key: capability_key, meta_value: capability_string)
    end

    # editing
    if(!richbum = self.blogs_usermetas.where(meta_key: 'rich_editing').first)
      richbum = self.blogs_usermetas.create(meta_key: 'rich_editing', meta_value: 'true')
    end

    bum

  end

end
