# global settings

@my_database = ActiveRecord::Base.connection.instance_variable_get("@config")[:database]
@darmok_database = 'prod_darmok'


## utility methods

def benchmark_queries(queries)
  benchmark = Benchmark.measure do
    queries.each do |query|
     ActiveRecord::Base.connection.execute(query)
    end
  end
  benchmark
end

def announce_and_run_query(label,query)
  print "#{label}..."
  benchmark = benchmark_queries([query])
  print "\t\tfinished in #{benchmark.real.round(1)}s\n"
end


## class definitions for data transformations

class DarmokAccount < ActiveRecord::Base
  base_config = ActiveRecord::Base.connection.instance_variable_get("@config").dup
  base_config[:database] = 'prod_darmok'
  establish_connection(base_config)
  self.set_table_name 'accounts'
  self.inheritance_column = "inheritance_type"

  serialize :additionaldata
end

class DarmokUserEvent < ActiveRecord::Base
  base_config = ActiveRecord::Base.connection.instance_variable_get("@config").dup
  base_config[:database] = 'prod_darmok'
  establish_connection(base_config)
  self.set_table_name 'user_events'
  serialize :additionaldata

  LOGIN_API_SUCCESS = 200
  LOGIN_OPENID_SUCCESS = 201
  LOGIN_LOCAL_SUCCESS = 202
  
  LOGIN_API_FAILED = 300
  LOGIN_LOCAL_FAILED = 302 
end

class DarmokAdminEvent< ActiveRecord::Base
  base_config = ActiveRecord::Base.connection.instance_variable_get("@config").dup
  base_config[:database] = 'admin_events'
  establish_connection(base_config)
  self.set_table_name 'activities'
  serialize :data
end

class DarmokActivity < ActiveRecord::Base
  base_config = ActiveRecord::Base.connection.instance_variable_get("@config").dup
  base_config[:database] = 'prod_darmok'
  establish_connection(base_config)
  self.set_table_name 'activities'
  serialize :additionaldata
end







def account_transfer_query
  reject_columns = ['password_hash','involvement','institution_id','invitation_id','token']
  columns = Person.column_names.reject{|n| reject_columns.include?(n)}
  insert_clause = "#{@my_database}.#{Person.table_name} (#{columns.join(',')})"
  from_clause = "#{@darmok_database}.accounts"
  select_columns = []
  columns.each do |c|
    case c
    when 'idstring'
      select_columns << "#{from_clause}.login"
    when 'legacy_password'
      select_columns << "#{from_clause}.password"
    else
      select_columns << "#{from_clause}.#{c}"
    end
  end
  select_clause = "#{select_columns.join(',')}"
  where_clause = "#{from_clause}.type = 'User'"
  account_transfer_query = "INSERT INTO #{insert_clause} SELECT #{select_clause} FROM #{from_clause} WHERE #{where_clause}"
  account_transfer_query
end


def google_account_transfer_query
  query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{@my_database}.#{GoogleAccount.table_name} SELECT * FROM #{@darmok_database}.google_accounts
  END_SQL
  query
end

def county_transfer_query
  query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{@my_database}.#{County.table_name} SELECT * FROM #{@darmok_database}.counties WHERE #{@darmok_database}.counties.name != 'all'
  END_SQL
  query
end

def location_transfer_query
  query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{@my_database}.#{Location.table_name} SELECT * FROM #{@darmok_database}.locations
  END_SQL
  query
end

def position_transfer_query
  query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{@my_database}.#{Position.table_name} SELECT * FROM #{@darmok_database}.positions
  END_SQL
  query
end

def community_transfer_query
  select_columns = Community.column_names
  insert_clause = "#{@my_database}.#{Community.table_name} (#{select_columns.join(',')})"
  from_clause = "#{@darmok_database}.communities"
  select_clause = "#{select_columns.join(',')}"
  where_clause = "#{from_clause}.entrytype IN (1,2,3)"
  transfer_query = "INSERT INTO #{insert_clause} SELECT #{select_clause} FROM #{from_clause} WHERE #{where_clause}"
  transfer_query
end

def community_connections_transfer_query
  query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{@my_database}.#{CommunityConnection.table_name} SELECT * FROM #{@darmok_database}.communityconnections WHERE connectiontype != 'nointerest'
  END_SQL
  query
end

def community_connections_change_wantstojoin_to_pending
  query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{@my_database}.#{CommunityConnection.table_name} SET connectiontype = 'pending' WHERE connectiontype = 'wantstojoin'
  END_SQL
  query
end

def google_groups_transfer_query
  query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{@my_database}.#{GoogleGroup.table_name} SELECT * FROM #{@darmok_database}.google_groups
  END_SQL
  query
end

def lists_transfer_query
  select_columns = MailmanList.column_names
  insert_clause = "#{@my_database}.#{MailmanList.table_name} (#{select_columns.join(',')})"
  from_clause = "#{@darmok_database}.lists"
  select_clause = "#{select_columns.join(',')}"
  transfer_query = "INSERT INTO #{insert_clause} SELECT #{select_clause} FROM #{from_clause}"
  transfer_query
end

def social_network_transfer_query
  insert_columns = SocialNetworkConnection.column_names
  insert_clause = "#{@my_database}.#{SocialNetworkConnection.table_name} (#{insert_columns.join(',')})"
  from_clause = "#{@darmok_database}.social_networks"
  select_columns = []
  insert_columns.each do |c|
    case c
    when 'person_id'
      select_columns << "#{from_clause}.user_id"
    else
      select_columns << "#{from_clause}.#{c}"
    end
  end
  select_clause = "#{select_columns.join(',')}"
  transfer_query = "INSERT INTO #{insert_clause} SELECT #{select_clause} FROM #{from_clause}"
  transfer_query
end

def individual_email_alias_query
  reject_columns = ['id','aliasable_type']
  columns = EmailAlias.column_names.reject{|n| reject_columns.include?(n)}
  insert_clause = "#{@my_database}.#{EmailAlias.table_name} (#{(['aliasable_type']+ columns).join(',')})"
  from_clause = "#{@darmok_database}.email_aliases"
  select_columns = []
  columns.each do |c|
    case c      
    when 'aliasable_id'
      select_columns << "#{from_clause}.user_id"
    else
      select_columns << "#{from_clause}.#{c}"
    end
  end
  select_clause = "#{(["'Person'"]+select_columns).join(',')}"
  where_clause = "#{from_clause}.user_id > 0"
  transfer_query = "INSERT INTO #{insert_clause} SELECT #{select_clause} FROM #{from_clause} WHERE #{where_clause}"
  transfer_query
end

def community_email_alias_query
  reject_columns = ['id','aliasable_type']
  columns = EmailAlias.column_names.reject{|n| reject_columns.include?(n)}
  insert_clause = "#{@my_database}.#{EmailAlias.table_name} (#{(['aliasable_type']+ columns).join(',')})"
  from_clause = "#{@darmok_database}.email_aliases"
  select_columns = []
  columns.each do |c|
    case c      
    when 'aliasable_id'
      select_columns << "#{from_clause}.community_id"
    else
      select_columns << "#{from_clause}.#{c}"
    end
  end
  select_clause = "#{(["'Community'"]+select_columns).join(',')}"
  where_clause = "#{from_clause}.community_id > 0"
  transfer_query = "INSERT INTO #{insert_clause} SELECT #{select_clause} FROM #{from_clause} WHERE #{where_clause}"
  transfer_query
end

def invitations_transfer_query
  query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{@my_database}.#{Invitation.table_name} SELECT * FROM #{@darmok_database}.invitations
  END_SQL
  query
end

def set_person_institution_column
  print "Setting person's institution column..."
  benchmark = Benchmark.measure do
    # get the primaries
    query = <<-END_SQL.gsub(/\s+/, " ").strip
      UPDATE #{@my_database}.#{Person.table_name}, #{@my_database}.#{CommunityConnection.table_name} 
      SET #{@my_database}.#{Person.table_name}.institution_id = #{@my_database}.#{CommunityConnection.table_name}.community_id
      WHERE #{@my_database}.#{CommunityConnection.table_name}.person_id = #{@my_database}.#{Person.table_name}.id
      AND #{@my_database}.#{CommunityConnection.table_name}.connectioncode = #{CommunityConnection::PRIMARY_INSTITUTION}
    END_SQL
    ActiveRecord::Base.connection.execute(query)

    # get the belongs to 1 where they don't have a primary for some reason
    Person.where("institution_id IS NULL").find_each do |person|
      if(person.communities.institutions.count == 1)
        person.update_column(:institution_id, person.communities.institutions.first.id)
      end
    end
  end
  print "\t\tfinished in #{benchmark.real.round(1)}s\n"
end


def transform_person_additionaldata_data
  print "Setting person's involvement column..."
  benchmark = Benchmark.measure do
    DarmokAccount.where("additionaldata LIKE '%:signup_affiliation%'").find_each do |darmok_account|
      if(signup_affiliation = darmok_account.additionaldata[:signup_affiliation])
        query = <<-END_SQL.gsub(/\s+/, " ").strip
          UPDATE #{@my_database}.#{Person.table_name} SET involvement = #{ActiveRecord::Base.quote_value(signup_affiliation)} WHERE id = #{darmok_account.id}
        END_SQL
        ActiveRecord::Base.connection.execute(query)        
      end
    end
  end
  print "\t\tfinished in #{benchmark.real.round(1)}s\n"

  print "Setting person's institution column for signups..."
  benchmark = Benchmark.measure do
    Person.where(account_status: Person::STATUS_SIGNUP).all.each do |person|
      darmok_account = DarmokAccount.find_by_id(person.id)
      if(darmok_account.additionaldata and signup_institution_id = darmok_account.additionaldata[:signup_institution_id])
        person.update_column(:institution_id, signup_institution_id)
      end
    end
  end
  print "\t\tfinished in #{benchmark.real.round(1)}s\n"  
end

def create_milfam_wordpress_list_email_alias
  print "Created military-families wordpress alias..."
  benchmark = Benchmark.measure do
    list = MailmanList.find_by_name('militaryfamilies-wordpress')
    EmailAlias.create(aliasable: list, mail_alias: list.name, destination: list.mailto, alias_type: EmailAlias::FORWARD)
  end
  print "\t\tfinished in #{benchmark.real.round(1)}s\n"
end

def dump_never_completed_signups
  print "Deleting accounts that have never completed signup (except those in last 14 days)..."
  benchmark = Benchmark.measure do
    Person.cleanup_signup_accounts
  end
  print "\t\tfinished in #{benchmark.real.round(1)}s\n" 
end

def transfer_user_authentication_events_to_activities
  print "Transferring authentication events to auth log"
  benchmark = Benchmark.measure do
    DarmokUserEvent.where("etype IN (200,201,202,300,302)").find_in_batches do |group|
      insert_values = []
      group.each do |user_event|
        insert_list = []
        insert_list << (user_event.user_id.nil? ? 'NULL' : user_event.user_id)
        insert_list << Activity::AUTHENTICATION
        case user_event.etype
        when DarmokUserEvent::LOGIN_LOCAL_SUCCESS
          insert_list << Activity::AUTH_LOCAL_SUCCESS
          insert_list << 'NULL'
        when DarmokUserEvent::LOGIN_API_SUCCESS
          insert_list << Activity::AUTH_REMOTE_SUCCESS
          insert_list << 'NULL'          
        when DarmokUserEvent::LOGIN_OPENID_SUCCESS
          insert_list << Activity::AUTH_REMOTE_SUCCESS
          insert_list << 'NULL'
        when DarmokUserEvent::LOGIN_LOCAL_FAILED
          insert_list << Activity::AUTH_LOCAL_FAILURE
          if(user_event.description =~ %r{incorrect password})
            insert_list << Activity::AUTH_INVALID_PASSWORD
          elsif(user_event.description =~ %r{invalid eXtensionID})
            insert_list << Activity::AUTH_INVALID_ID
          elsif(user_event.description =~ %r{expired password})
            insert_list << Activity::AUTH_PASSWORD_EXPIRED
          elsif(user_event.description =~ %r{account})
            insert_list << Activity::AUTH_ACCOUNT_RETIRED
          else
            insert_list << Activity::AUTH_UNKNOWN
          end
        when DarmokUserEvent::LOGIN_API_FAILED
          insert_list << Activity::AUTH_LOCAL_FAILURE
          if(user_event.description =~ %r{incorrect password})
            insert_list << Activity::AUTH_INVALID_PASSWORD
          elsif(user_event.description =~ %r{invalid eXtensionID})
            insert_list << Activity::AUTH_INVALID_ID
          elsif(user_event.description =~ %r{expired password})
            insert_list << Activity::AUTH_PASSWORD_EXPIRED
          elsif(user_event.description =~ %r{account})
            insert_list << Activity::AUTH_ACCOUNT_RETIRED
          else
            insert_list << Activity::AUTH_UNKNOWN
          end
        else
          # uh-oh what happened?
          insert_list << 0
          insert_list << 'NULL'
        end
        insert_list << ActiveRecord::Base.quote_value(user_event.login)
        insert_list << ActiveRecord::Base.quote_value(user_event.appname)
        insert_list << ActiveRecord::Base.quote_value(user_event.ip)
        insert_list << ActiveRecord::Base.quote_value(user_event.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{Activity.table_name} (person_id,activityclass,activitycode,reasoncode,additionalinfo,site,ip_address,created_at) VALUES #{insert_values.join(',')};"
      ActiveRecord::Base.connection.execute(insert_sql)        
    end
  end
  print "\t\tfinished in #{benchmark.real.round(1)}s\n"
end

# seed queries
announce_and_run_query('Transferring accounts',account_transfer_query)
announce_and_run_query('Transferring google accounts',google_account_transfer_query)
announce_and_run_query('Transferring counties',county_transfer_query)
announce_and_run_query('Transferring locations',location_transfer_query)
announce_and_run_query('Transferring positions',position_transfer_query)
announce_and_run_query('Transferring communities',community_transfer_query)
announce_and_run_query('Transferring community connections',community_connections_transfer_query)
announce_and_run_query('Changing wantstojoin to pending',community_connections_change_wantstojoin_to_pending)
announce_and_run_query('Transferring google groups',google_groups_transfer_query)
announce_and_run_query('Transferring lists',lists_transfer_query)
announce_and_run_query('Transferring social network connections',social_network_transfer_query)
announce_and_run_query('Transferring individual email aliases',individual_email_alias_query)
announce_and_run_query('Transferring community email aliases',community_email_alias_query)
announce_and_run_query('Transferring invitations',invitations_transfer_query)

# data manipulation
dump_never_completed_signups
create_milfam_wordpress_list_email_alias
set_person_institution_column
transform_person_additionaldata_data
transfer_user_authentication_events_to_activities


