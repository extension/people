# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class CommunitySync < ActiveRecord::Base
  serialize :errors
  attr_accessible :success, :errors
  attr_accessible :community, :community_id, :processed, :process_on_create

  UPDATE_DATABASES = {'create_database' => Settings.create_database,
                      'www_database' => Settings.www_database}

  after_create  :queue_update

  belongs_to :community

  scope :not_processed, -> { where(processed: false)}

  def queue_update
    if(self.process_on_create? or !Settings.redis_enabled)
      self.update_communities
    else
      self.class.delay_for(5.seconds).delayed_update_communities(self.id)
    end
  end

  def self.delayed_update_communities(record_id)
    if(record = find_by_id(record_id))
      record.update_communities
    end
  end

  def update_communities
    if(!self.processed?)
      begin
        UPDATE_DATABASES.keys.each do |sync_target|
          self.send(sync_target)
        end
        self.update_attributes({processed: true, success: true})
      rescue StandardError => e
        self.update_attributes({processed: true, success: false, errors: e.message})
      end
    end
  end

  def create_database
    if(self.community.connect_to_drupal)
      if(self.community.drupal_node_id.blank?)
        create_insert_community
      else
        create_update_community
      end
    end
  end

  def www_database
    if(publishing_community = DarmokPublishingCommunity.find_by_id(self.community_id))
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
            #{quoted_value_or_null(community.created_at.to_s(:db))},
            NOW()
    END_SQL
    query
  end

  def create_insert_community
    community = self.community
    update_database = UPDATE_DATABASES['create_database']

    ## node_revision insertion
    sql = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.node_revision (nid,uid,title,log,timestamp)
    SELECT 0,
           1,
           #{ActiveRecord::Base.quote_value(community.name)},
           'Added by synchronization script',
           UNIX_TIMESTAMP()
    END_SQL
    self.connection.execute(sql)

    ## node insertion
    sql = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.node (vid,type,language,title,uid,created,changed,promote)
    SELECT vid,
           'group',
           'und',
           #{update_database}.node_revision.title,
           1,
           UNIX_TIMESTAMP(),
           UNIX_TIMESTAMP(),
           1
    FROM #{update_database}.node_revision
    WHERE #{update_database}.node_revision.nid = 0
    AND   #{update_database}.node_revision.log = 'Added by synchronization script'
    AND   #{update_database}.node_revision.title = #{ActiveRecord::Base.quote_value(community.name)}
    END_SQL
    self.connection.execute(sql)


    ## set the node_revision node id based on name match
    sql = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.node_revision,#{update_database}.node
    SET #{update_database}.node_revision.nid = #{update_database}.node.nid
    WHERE #{update_database}.node.vid = #{update_database}.node_revision.vid
    AND #{update_database}.node.type = 'group'
    AND #{update_database}.node_revision.title = #{update_database}.node.title
    AND #{update_database}.node_revision.title = #{ActiveRecord::Base.quote_value(community.name)}
    END_SQL
    self.connection.execute(sql)


    ## set the darmok community association based on name
    sql = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{Community.table_name},#{update_database}.node
    SET #{Community.table_name}.drupal_node_id = #{update_database}.node.nid
    WHERE #{update_database}.node.type = 'group'
    AND   #{Community.table_name}.drupal_node_id IS NULL
    AND   #{update_database}.node.title = #{ActiveRecord::Base.quote_value(community.name)}
    AND   #{Community.table_name}.id = #{community.id}
    END_SQL
    self.connection.execute(sql)

    # reload now that we have a drupal_node_id
    community.reload

    if(!community.drupal_node_id.blank?)
      ## node_access
      sql = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT INTO #{update_database}.node_access (nid,gid,realm,grant_view,grant_update,grant_delete)
      SELECT #{community.drupal_node_id},
             0,
             'all',
             1,
             0,
             0
      END_SQL
      self.connection.execute(sql)

      ## og
      sql = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT INTO #{update_database}.og (gid,etid,entity_type,label,state,created)
      SELECT #{community.drupal_node_id},
             #{community.drupal_node_id},
             'node',
             #{ActiveRecord::Base.quote_value(community.name)},
             1,
             #{community.created_at.to_i}
      END_SQL
      self.connection.execute(sql)

      ## og user roles
      # hardcoded roles - do not change these roles in drupal!!  leader = 3 member = 2
      sql = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT IGNORE INTO #{update_database}.og_users_roles (uid,rid,gid)
      SELECT #{CommunityConnection.table_name}.person_id,
             IF(#{CommunityConnection.table_name}.connectiontype = 'leader',3,2),
             #{update_database}.og.gid
      FROM  #{update_database}.og, #{CommunityConnection.table_name}
      WHERE #{update_database}.og.etid = #{community.drupal_node_id}
        AND #{CommunityConnection.table_name}.community_id = #{community.id}
        AND #{CommunityConnection.table_name}.connectiontype IN ('leader','member')
      END_SQL
      self.connection.execute(sql)

      # og_membership
      sql = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT IGNORE INTO #{update_database}.og_membership (type, etid, entity_type, gid, state, created)
      SELECT 'og_membership_type_default',
             #{CommunityConnection.table_name}.person_id,
             'user',
             #{update_database}.og.gid,
             '1',
             UNIX_TIMESTAMP('#{CommunityConnection.table_name}.created_at')
      FROM #{update_database}.og,#{CommunityConnection.table_name}
      WHERE #{update_database}.og.etid = #{community.drupal_node_id}
        AND #{CommunityConnection.table_name}.community_id = #{community.id}
        AND #{CommunityConnection.table_name}.connectiontype IN ('leader','member')
      END_SQL
      self.connection.execute(sql)


      # group audience field
      # etid is field_config_entity_type for 'user' == 3 - hardcoded!
      # Note: delta is a hack! there's an primary index on etid+revision_id+deleted+delta+langague and since revision_id == the uid, this means that
      # every user row gets an incremented delta.  Trying to query on this and insert is a hard problem(tm) (it can be done with max(delta), but you
      # have to make a couple of passes, and I haven't figured it out yet.  So, I'm setting delta to the gid.  I don't think delta is used in the queries)
      ['data','revision'].each do |field_table|
        sql = <<-END_SQL.gsub(/\s+/, " ").strip
        INSERT IGNORE INTO #{update_database}.field_#{field_table}_group_audience (bundle,deleted,entity_id,revision_id,language,delta,group_audience_gid,group_audience_state,group_audience_created,entity_type)
        SELECT 'user',
               0,
               #{CommunityConnection.table_name}.person_id,
               #{CommunityConnection.table_name}.person_id,
               'und',
               #{update_database}.og.gid,
               #{update_database}.og.gid,
               1,
               UNIX_TIMESTAMP('#{CommunityConnection.table_name}.created_at'),
               'user'
          FROM #{update_database}.og,#{CommunityConnection.table_name}
          WHERE #{update_database}.og.etid = #{community.drupal_node_id}
            AND #{CommunityConnection.table_name}.community_id = #{community.id}
            AND #{CommunityConnection.table_name}.connectiontype IN ('leader','member')
        END_SQL
        self.connection.execute(sql)
      end

      # $@#%!^!#%@$!@#$ FIELDS INSERTS
      ['data','revision'].each do |field_table|
        sql = <<-END_SQL.gsub(/\s+/, " ").strip
        INSERT IGNORE INTO #{update_database}.field_#{field_table}_group_group (bundle,deleted,entity_id,revision_id,language,delta,group_group_value,entity_type)
          SELECT 'group',
                 0,
                 #{community.drupal_node_id},
                 #{update_database}.node.vid,
                 'und',
                 0,
                 1,
                 'node'
          FROM #{update_database}.node
          WHERE #{update_database}.node.nid = #{community.drupal_node_id}
        END_SQL
        self.connection.execute(sql)
      end

      ['data','revision'].each do |field_table|
        sql = <<-END_SQL.gsub(/\s+/, " ").strip
        INSERT INTO #{update_database}.field_#{field_table}_field_group_designation (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_group_designation_value)
          SELECT 'node',
                 'group',
                 0,
                 #{community.drupal_node_id},
                 #{community.drupal_node_id},
                 'und',
                 0,
                 #{community.entrytype}
          ON DUPLICATE KEY
          UPDATE field_group_designation_value=#{community.entrytype}
        END_SQL
        self.connection.execute(sql)
      end
    end # if the drupal_node_id exists
  end

  def create_update_community
    community = self.community
    update_database = UPDATE_DATABASES['create_database']

    ## update the nodes table
    sql = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.node
    SET #{update_database}.node.title = #{ActiveRecord::Base.quote_value(community.name)},
        #{update_database}.node.uid = 1
    WHERE #{update_database}.node.nid =  #{community.drupal_node_id}
    AND #{update_database}.node.type = 'group'
    END_SQL
    self.connection.execute(sql)

    ## update revisions table
    sql = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.node_revision,#{update_database}.node
    SET #{update_database}.node_revision.title = #{update_database}.node.title,
        #{update_database}.node_revision.log = 'Updated by synchronization script',
        #{update_database}.node_revision.uid = 1
    WHERE #{update_database}.node.vid = #{update_database}.node_revision.vid
    AND #{update_database}.node.type = 'group'
    AND #{update_database}.node_revision.title != #{update_database}.node.title
    AND #{update_database}.node.nid =  #{community.drupal_node_id}
    END_SQL
    self.connection.execute(sql)

    ## og
    sql = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.og
    SET #{update_database}.og.label = #{ActiveRecord::Base.quote_value(community.name)}
    WHERE #{update_database}.og.gid = #{community.drupal_node_id}
    END_SQL
    self.connection.execute(sql)

    # $@#%!^!#%@$!@#$ FIELDS INSERTS
    ['data','revision'].each do |field_table|
      sql = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT IGNORE INTO #{update_database}.field_#{field_table}_group_group (bundle,deleted,entity_id,revision_id,language,delta,group_group_value,entity_type)
        SELECT 'group',
               0,
               #{community.drupal_node_id},
               #{update_database}.node.vid,
               'und',
               0,
               1,
               'node'
        FROM #{update_database}.node
        WHERE #{update_database}.node.nid = #{community.drupal_node_id}
      END_SQL
      self.connection.execute(sql)
    end

    ['data','revision'].each do |field_table|
      sql = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT INTO #{update_database}.field_#{field_table}_field_group_designation (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_group_designation_value)
        SELECT 'node',
               'group',
               0,
               #{community.drupal_node_id},
               #{community.drupal_node_id},
               'und',
               0,
               #{community.entrytype}
        ON DUPLICATE KEY
        UPDATE field_group_designation_value=#{community.entrytype}
      END_SQL
      self.connection.execute(sql)
    end
  end

  def value_or_null(value)
    value.blank? ? 'NULL' : value
  end

  def quoted_value_or_null(value)
    value.blank? ? 'NULL' : ActiveRecord::Base.quote_value(value)
  end

end
