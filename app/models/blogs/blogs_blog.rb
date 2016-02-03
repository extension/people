# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class BlogsBlog < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :blogs
  self.table_name='wp_blogs'
  self.primary_key = 'blog_id'


  def access_list
    returnhash = {}
    meta_key = "wp_#{self.blog_id}_capabilities"
    if(usermeta_group = BlogsUsermeta.where(meta_key: meta_key))
      usermeta_group.each do |bum|
        if(person = Person.where(id: bum.user_id).first)
          permission = PHP.unserialize(bum.meta_value)
          permission_string = permission.keys.first
          returnhash[person] = permission_string
        end
      end
    end
    returnhash
  end

  def name
    if(self.path == '/')
      'Blogs Root'
    elsif(self.path =~ %r{/([\w-]+)/})
      $1
    else
      "Blogs #{self.blog_id}"
    end
  end


end
