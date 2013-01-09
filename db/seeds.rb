# global settings

@my_database = ActiveRecord::Base.connection.instance_variable_get("@config")[:database]
@darmok_database = 'prod_darmok'

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
  reject_columns = ['password_digest']
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
    INSERT INTO #{@my_database}.#{County.table_name} SELECT * FROM #{@darmok_database}.counties
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

