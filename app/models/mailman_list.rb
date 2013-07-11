# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class MailmanList < ActiveRecord::Base
  belongs_to :community

  scope :joined, -> { where(connectiontype: 'joined')}
  scope :leaders, -> { where(connectiontype: 'leaders')}

  def mailto
    "#{self.name}@lists.extension.org"
  end

  def convert_to_google_group(shortname = '')
    # jgg flag
    if(self.connectiontype == 'leaders')
      if(self.community.joined_google_group.blank?)
        created_jgg = true
      end
    end

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
        if(created_jgg and jgg = self.community.joined_google_group)
          puts "https://groups.google.com/a/extension.org/forum/#!groupsettings/#{jgg.group_id}/content"
        end
        puts "https://groups.google.com/a/extension.org/forum/#!groupsettings/#{gg.group_id}/content"
        return gg
      else
        return nil
      end
    else
      return nil
    end
  end


  def self.transition_google_group_aliases
    query = <<-END_SQL.gsub(/\s+/, " ").strip
      UPDATE email_aliases,communities,google_groups
      SET email_aliases.aliasable_type = 'GoogleGroup', email_aliases.aliasable_id = google_groups.id
      WHERE email_aliases.aliasable_type = 'Community' and email_aliases.aliasable_id = communities.id
      AND google_groups.community_id = communities.id
    END_SQL
    result = self.connection.execute(query)

    delete_query = "DELETE from email_aliases where email_aliases.aliasable_type = 'Community'"
    delete_result = self.connection.execute(delete_query)
    [result,delete_result]
  end
  
end