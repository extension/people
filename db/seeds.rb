# global settings

@my_database = ActiveRecord::Base.connection.instance_variable_get("@config")[:database]
@darmok_database = 'prod_darmok'

class DarmokAccount < ActiveRecord::Base
  base_config = ActiveRecord::Base.connection.instance_variable_get("@config").dup
  base_config[:database] = 'prod_darmok'
  establish_connection(base_config)
  self.set_table_name 'accounts'
  self.inheritance_column = "inheritance_type"

  serialize :additionaldata
end


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


def set_person_involvement_column
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
end

def create_milfam_wordpress_list_email_alias
  print "Created military-families wordpress alias..."
  benchmark = Benchmark.measure do
    list = MailmanList.find_by_name('militaryfamilies-wordpress')
    EmailAlias.create(aliasable: list, mail_alias: list.name, destination: list.mailto, alias_type: EmailAlias::FORWARD)
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
create_milfam_wordpress_list_email_alias
set_person_institution_column
set_person_involvement_column


