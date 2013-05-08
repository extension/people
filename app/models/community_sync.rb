# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CommunitySync < ActiveRecord::Base
  belongs_to :community
  attr_accessible :community, :community_id, :processed, :sync_on_create


  UPDATE_DATABASES = {'www_database' => Settings.www_database}

  after_create  :queue_update

  def queue_update
    if(self.sync_on_create?)
      self.update_communities
    else
      self.delay.update_communities
    end
  end

  def update_communities
    if(!self.processed?)
      UPDATE_DATABASES.keys.each do |sync_target|
        self.send(sync_target)
      end
      self.update_attributes({processed: true})
    end
  end


  def www_database
    if(publishing_community = DarmokPublishingCommunity.find_by_id(self.id))
      if(self.community.publishing_community?)
        self.connection.execute(www_update_query)
      else
        self.connection.execute(www_delete_query)
      end
    elsif(self.community.publishing_community?)
      self.connection.execute(www_insert_query)
    end    
  end


  def www_update_query
    community = self.community
    update_database = UPDATE_DATABASES['www_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.publishing_communities
    SET #{update_database}.publishing_communities.name            = #{quoted_value_or_null(community.name)},
        #{update_database}.publishing_communities.drupal_node_id  = #{community.drupal_node_id},
        #{update_database}.publishing_communities.updated_at =    NOW()
    WHERE #{update_database}.publishing_communities.id = #{community.id}
    END_SQL
    query   
  end

  def www_delete_query
    community = self.community
    update_database = UPDATE_DATABASES['www_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    DELETE FROM #{update_database}.publishing_communities WHERE #{update_database}.publishing_communities.id = #{community.id}
    END_SQL
    query   
  end

  def www_insert_query
    community = self.community
    update_database = UPDATE_DATABASES['www_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.publishing_communities (id,name,drupal_node_id,created_at,updated_at) 
    SELECT  #{community.id},
            #{quoted_value_or_null(community.name)},
            #{community.drupal_node_id},
            #{quoted_value_or_null(person.created_at.to_s(:db))},
            NOW()
    END_SQL
    query    
  end


  def value_or_null(value)
    value.blank? ? 'NULL' : value
  end

  def quoted_value_or_null(value)
    value.blank? ? 'NULL' : ActiveRecord::Base.quote_value(value)
  end

end