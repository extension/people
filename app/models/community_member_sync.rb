# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CommunityMemberSync < ActiveRecord::Base
  serialize :errors
  attr_accessible :success, :errors
  attr_accessible :community, :community_id, :person, :person_id, :processed, :process_on_create

  UPDATE_DATABASES = {'create_database' => Settings.create_database}

  after_create  :queue_update

  belongs_to :community
  belongs_to :person


  def self.create_with_pending_check(options)
    if(!(sync_record = self.where(community_id: options[:community].id).where(person_id: options[:person].id).where(processed: false).first))
      self.create(options)
    end
  end

  def queue_update
    if(self.process_on_create? or !Settings.redis_enabled)
      self.update_community_members
    else
      self.class.delay.delayed_update_community_members(self.id)
    end
  end

  def self.delayed_update_community_members(record_id)
    if(record = find_by_id(record_id))
      record.update_community_members
    end
  end  

  def update_community_members
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
    person = self.person
    community = self.community
    connection = person.connection_with_community(community)
    return if (!community.connect_to_drupal? or community.drupal_node_id.blank?)

    # deletes
    create_membership_deletes
    if(['leader','member'].include?(connection))
      create_membership_inserts
    end      
  end


  def create_membership_deletes
    person = self.person
    community = self.community
    update_database = UPDATE_DATABASES['create_database']
    return if (community.drupal_node_id.blank?)
    
    # og user roles
    self.connection.execute("DELETE FROM #{update_database}.og_users_roles where uid = #{person.id} and gid = #{community.drupal_node_id}")
  
    # og_membership
    self.connection.execute("DELETE FROM #{update_database}.og_membership where etid = #{person.id} and gid = #{community.drupal_node_id}")

    # # group audience field
    ['data','revision'].each do |field_table|
     self.connection.execute("DELETE FROM #{update_database}.field_#{field_table}_group_audience where entity_id = #{person.id} and group_audience_gid = #{community.drupal_node_id}")
    end
  end


  def create_membership_inserts
    person = self.person
    community = self.community
    update_database = UPDATE_DATABASES['create_database']  
    connection = person.connection_with_community(community)
    return if (!community.connect_to_drupal? or community.drupal_node_id.blank?)
    return if !(['leader','member'].include?(connection))

    ## og user roles
    # hardcoded roles - do not change these roles in drupal!!  leader = 3 member = 2
    sql = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT IGNORE INTO #{update_database}.og_users_roles (uid,rid,gid) 
    SELECT #{person.id},
           #{(connection == 'leader') ? 3 : 2},
           #{community.drupal_node_id} 
    END_SQL
    self.connection.execute(sql)

    # og_membership
    sql = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT IGNORE INTO #{update_database}.og_membership (type, etid, entity_type, gid, state, created) 
    SELECT 'og_membership_type_default', 
           #{person.id},
           'user',
           #{community.drupal_node_id}, 
           '1',
           UNIX_TIMESTAMP()
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
             #{person.id},
             #{person.id}, 
             'und',
             #{community.drupal_node_id}, 
             #{community.drupal_node_id}, 
             1,
             UNIX_TIMESTAMP(),
             'user' 
      END_SQL
      self.connection.execute(sql)
    end 

  end



end