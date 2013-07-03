# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class MailmanList < ActiveRecord::Base
  belongs_to :community
  has_many :email_aliases

  scope :joined, -> { where(connectiontype: 'joined')}

  def mailto
    "#{self.name}@lists.extension.org"
  end

  def convert_to_google_group(shortname = '')
    community_attributes = {connect_to_google_apps: true}
    if(!shortname.blank?)
      if(Community.check_shortname(shortname,self.community))
        community_attributes[:shortname] = shortname
      else
        return nil
      end
    end

    if(self.community.update_attributes(community_attributes))
      if(self.connectiontype == 'joined')
        gg = self.community.joined_google_group
      elsif(self.connectiontype == 'leaders')
        if(!gg = self.community.leaders_google_group)
          gg = self.community.create_leaders_google_group
        end
      else
        return nil
      end

      if(gg)
        gg.update_column(:lists_alias,self.name)
        gg.queue_members_update
        self.destroy
        puts gg.forum_url
        return gg
      else
        return nil
      end
    else
      return nil
    end
  end
  
end