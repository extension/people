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
  base_config[:database] = 'prod_darmok'
  establish_connection(base_config)
  self.set_table_name 'admin_events'
  serialize :data
end

class DarmokActivity < ActiveRecord::Base
  base_config = ActiveRecord::Base.connection.instance_variable_get("@config").dup
  base_config[:database] = 'prod_darmok'
  establish_connection(base_config)
  self.set_table_name 'activities'
  serialize :additionaldata
end

class DarmokCommunityConnection < ActiveRecord::Base
  base_config = ActiveRecord::Base.connection.instance_variable_get("@config").dup
  base_config[:database] = 'prod_darmok'
  establish_connection(base_config)
  self.set_table_name 'communityconnections'

  # codes
  INVITEDLEADER = 201
  INVITEDMEMBER = 202
  
end


def account_transfer_query
  reject_columns = ['password_hash','involvement','institution_id','invitation_id']
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

def transfer_community_connections
  print "Transferring community connections..."
  benchmark = Benchmark.measure do
    DarmokCommunityConnection.find_in_batches do |group|
      insert_values = []
      group.each do |connection|
        # don't port interest
        next if connection.connectiontype == 'interest'
        insert_list = []
        insert_list << connection.user_id
        insert_list << connection.community_id
        if(connection.connectiontype == 'wantstojoin')
          insert_list << ActiveRecord::Base.quote_value('pending')
        elsif(connection.connectiontype == 'invited')
          if(connection.connectioncode == DarmokCommunityConnection::INVITEDLEADER)
            insert_list << ActiveRecord::Base.quote_value('invitedleader')
          else
            insert_list << ActiveRecord::Base.quote_value('invitedmember')
          end
        else
          insert_list << ActiveRecord::Base.quote_value(connection.connectiontype)
        end
        insert_list << (connection.sendnotifications ? 1 : 0 )
        insert_list << ActiveRecord::Base.quote_value(connection.created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(connection.updated_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{CommunityConnection.table_name} (person_id,community_id,connectiontype,sendnotifications,created_at,updated_at) VALUES #{insert_values.join(',')};"
      ActiveRecord::Base.connection.execute(insert_sql)        
    end
  end
  print "\t\tfinished in #{benchmark.real.round(1)}s\n"
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
  reject_columns = ['id','social_network_id']
  insert_columns = SocialNetworkConnection.column_names.reject{|n| reject_columns.include?(n)}
  insert_clause = "#{@my_database}.#{SocialNetworkConnection.table_name} (#{insert_columns.join(',')})"
  from_clause = "#{@darmok_database}.social_networks"
  select_columns = []
  insert_columns.each do |c|
    case c
    when 'person_id'
      select_columns << "#{from_clause}.user_id"
    when 'network_name'
      select_columns << "#{from_clause}.network"
    when 'custom_network_name'
      select_columns << "#{from_clause}.displayname"
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
      UPDATE #{@my_database}.#{Person.table_name}, #{@darmok_database}.#{DarmokCommunityConnection.table_name} 
      SET #{@my_database}.#{Person.table_name}.institution_id = #{@darmok_database}.#{DarmokCommunityConnection.table_name}.community_id
      WHERE #{@darmok_database}.#{DarmokCommunityConnection.table_name}.user_id = #{@my_database}.#{Person.table_name}.id
      AND #{@darmok_database}.#{DarmokCommunityConnection.table_name}.connectioncode = 101
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
  print "Transferring authentication events to activity log..."
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


def transfer_user_profile_events_to_activities
  print "Transferring profile events to activity log..."
  benchmark = Benchmark.measure do
    DarmokUserEvent.where("etype = 3").find_in_batches do |group|
      insert_values = []
      group.each do |user_event|
        next if(user_event.description =~ %r{vouched}) 
        next if(user_event.description =~ %r{retired}) 
        insert_list = []
        insert_list << (user_event.user_id.nil? ? 'NULL' : user_event.user_id)
        insert_list << Activity::PEOPLE
        insert_list << Activity::UPDATE_PROFILE
        insert_list << ActiveRecord::Base.quote_value(user_event.description)
        insert_list << ActiveRecord::Base.quote_value(user_event.appname)
        insert_list << ActiveRecord::Base.quote_value(user_event.ip)
        insert_list << ActiveRecord::Base.quote_value(user_event.created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(user_event.read_attribute(:additionaldata))      
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{Activity.table_name} (person_id,activityclass,activitycode,additionalinfo,site,ip_address,created_at,additionaldata) VALUES #{insert_values.join(',')};"
      ActiveRecord::Base.connection.execute(insert_sql)        
    end
  end
  print "\t\tfinished in #{benchmark.real.round(1)}s\n"
end

def transfer_admin_events_to_activities
  print "Transferring admin events to activity log..."
  benchmark = Benchmark.measure do
    DarmokAdminEvent.where("event IN (3,4)").find_in_batches do |group|
      insert_values = []
      group.each do |admin_event|
        next if admin_event.data.nil?
        if(admin_event.data.is_a?(String))
          extensionid = admin_event.data
        else
          next if admin_event.data[:extensionid].nil?
          extensionid = admin_event.data[:extensionid]
          reason = admin_event.data[:reason]
        end
        next if(!(person = Person.where('idstring = ?',extensionid).first))
        insert_list = []
        insert_list << (person.id)
        insert_list << Activity::ADMIN
        insert_list << (admin_event.event == 3) ? Activity::ENABLE_ACCOUNT : Activity::RETIRE_ACCOUNT
        insert_list << (reason.nil? ? 'NULL' : ActiveRecord::Base.quote_value(reason))
        insert_list << ActiveRecord::Base.quote_value('local')
        insert_list << ActiveRecord::Base.quote_value(admin_event.ip)
        insert_list << ActiveRecord::Base.quote_value(admin_event.created_at.to_s(:db))
        if(admin_event.data.is_a?(String))
          additionaldata = {extra: admin_event.data}.to_yaml
        else
          additionaldata = admin_event.read_attribute(:data)
        end
        insert_list << ActiveRecord::Base.quote_value(additionaldata)      
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{Activity.table_name} (person_id,activityclass,activitycode,additionalinfo,site,ip_address,created_at,additionaldata) VALUES #{insert_values.join(',')};"
      ActiveRecord::Base.connection.execute(insert_sql)        
    end
  end
  print "\t\tfinished in #{benchmark.real.round(1)}s\n"
end

def transfer_activities_to_activities
  print "Transferring activities to activity log..."
  benchmark = Benchmark.measure do
    DarmokActivity.where("activitycode NOT IN (105,103,106,107)").find_in_batches do |group|
      insert_values = []
      group.each do |activity|
        insert_list = []
        if(activity.activitycode.between?(200,500) and ![208,209].include?(activity.activitycode))
          # community activity
          insert_list << (activity.created_by)
          if(activity.activitycode.between?(210,216))
            insert_list << (activity.user_id.nil? ? 'NULL' : activity.user_id)
          else
            insert_list << (activity.colleague_id.nil? ? 'NULL' : activity.colleague_id)
          end
          insert_list << (activity.community_id.nil? ? 'NULL' : activity.community_id)
          insert_list << Activity::COMMUNITY
          insert_list << activity.activitycode
          insert_list << 'NULL'
        elsif(activity.activitycode == 110)
          insert_list << (activity.created_by)
          insert_list << 'NULL'          
          insert_list << (activity.community_id.nil? ? 'NULL' : activity.community_id)
          insert_list << Activity::COMMUNITY
          insert_list << Activity::COMMUNITY_CREATE
          insert_list << 'NULL'
        elsif(activity.activitycode == 104)
          insert_list << (activity.created_by)
          insert_list << (activity.colleague_id.nil? ? 'NULL' : activity.colleague_id)
          insert_list << 'NULL'
          insert_list << Activity::PEOPLE
          insert_list << Activity::VOUCHED_FOR
          if(activity.additionaldata.is_a?(String))
            explanation = activity.additionaldata
          elsif activity.additionaldata[:explanation].nil?
            explanation = activity.additionaldata[:explanation]
          end
          insert_list << ActiveRecord::Base.quote_value(explanation)
        else
          insert_list << (activity.user_id.nil? ? 'NULL' : activity.user_id)
          insert_list << (activity.colleague_id.nil? ? 'NULL' : activity.colleague_id)
          insert_list << (activity.community_id.nil? ? 'NULL' : activity.community_id)
          insert_list << Activity::PEOPLE
          insert_list << activity.activitycode
          insert_list << 'NULL'
        end          
        insert_list << ActiveRecord::Base.quote_value('local')
        insert_list << ActiveRecord::Base.quote_value(activity.ipaddr)
        insert_list << ActiveRecord::Base.quote_value(activity.created_at.to_s(:db))
        if(activity.additionaldata.is_a?(String))
          additionaldata = {extra: activity.additionaldata}.to_yaml
        else
          additionaldata = activity.read_attribute(:additionaldata)
        end
        insert_list << ActiveRecord::Base.quote_value(additionaldata)   
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{Activity.table_name} (person_id,colleague_id,community_id,activityclass,activitycode,additionalinfo,site,ip_address,created_at,additionaldata) VALUES #{insert_values.join(',')};"
      ActiveRecord::Base.connection.execute(insert_sql)        
    end
  end
  print "\t\tfinished in #{benchmark.real.round(1)}s\n"
end

def associate_social_networks
  print "Associating social network connections to social networks..."
  benchmark = Benchmark.measure do
    networks = {
      'google' => {:display_name => 'Google', :editable_url => false, :autocomplete => false},
      'twitter' => {:display_name => 'Twitter', :url_format => 'http://twitter.com/%s', :editable_url => false, :autocomplete => true},
      'friendfeed' => {:display_name => 'FriendFeed', :url_format => 'http://friendfeed.com/%s', :editable_url => false, :autocomplete => true},
      'flickr' => {:display_name => 'Flickr', :url_format => 'http://flickr.com/photos/%s', :editable_url => true, :autocomplete => true, :url_format_notice => 'Your URL will not include your account name unless you have customized the settings in your Flickr account. Please confirm the link to your page.'},
      'facebook' => {:display_name => 'Facebook', :editable_url => true, :autocomplete => false},
      'magnolia' => {:display_name => 'Ma.gnolia', :url_format => 'http://ma.gnolia.com/people/%s', :editable_url => false, :autocomplete => true},
      'delicious' => {:display_name => 'Delicious', :url_format => 'http://delicious.com/%s', :editable_url => false, :autocomplete => true},
      'linkedin' => {:display_name => 'LinkedIn', :url_format => 'http://www.linkedin.com/in/%s', :editable_url => true, :autocomplete => true, :url_format_notice => '<span>http://www.linkedin.com/in/<strong>your-name</strong></span>You will need to create a custom LinkedIn Public Profile URL for the automatic linking to work.'},
      'slideshare' => {:display_name => 'SlideShare', :url_format => 'http://slideshare.net/%s', :editable_url => false, :autocomplete => true},
      'youtube' => {:display_name => 'YouTube', :url_format => 'http://www.youtube.com/user/%s', :editable_url => false, :autocomplete => true},
      'identica' => {:display_name => 'Identi.ca', :url_format => 'http://identi.ca/%s', :editable_url => false, :autocomplete => true},
      'aim' => {:display_name => 'AOL Instant Messenger', :url_format => 'aim:goim?%s', :editable_url => false, :autocomplete => true},
      'msnim' => {:display_name => 'MSN Instant Messenger', :editable_url => false, :autocomplete => true},
      'yahooim' => {:display_name => 'Yahoo Instant Messenger', :url_format => 'ymsgr:sendim?%s', :editable_url => false, :autocomplete => true},
      'gtalk' => {:display_name => 'Google Talk', :url_format => 'xmpp:%s', :editable_url => false, :autocomplete => true},
      'jabber' => {:display_name => 'Jabber/XMPP', :url_format => 'xmpp:%s', :editable_url => false, :autocomplete => true}, 
      'skype' => {:display_name => 'Skype', :url_format => 'skype:%s', :editable_url => false, :autocomplete => true},
      'gizmo' => {:display_name => 'Gizmo5', :url_format => 'gizmo:%s', :editable_url => false, :autocomplete => true},
      'wave' => {:display_name => 'Google Wave', :editable_url => false, :autocomplete => false, :active => false},
      'blog' => {:display_name => 'Blog/Website', :editable_url => true, :autocomplete => false},
      'secondlife' => {:display_name => 'Second Life', :editable_url => false, :autocomplete => false},
      'other' => {:display_name => 'Other', :editable_url => false, :autocomplete => false}
    }

    networks.each do |network,attributes|
      SocialNetwork.create(attributes.merge({name: network}))
    end

    SocialNetworkConnection.all.each do |snc|
      if(!sn = SocialNetwork.find_by_name(snc.network_name))
        sn = SocialNetwork.find_by_name('other')
      end
      snc.update_column(:social_network_id,sn.id)
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
announce_and_run_query('Transferring google groups',google_groups_transfer_query)
announce_and_run_query('Transferring lists',lists_transfer_query)
announce_and_run_query('Transferring social network connections',social_network_transfer_query)
announce_and_run_query('Transferring individual email aliases',individual_email_alias_query)
announce_and_run_query('Transferring community email aliases',community_email_alias_query)
announce_and_run_query('Transferring invitations',invitations_transfer_query)

# data manipulation
dump_never_completed_signups
create_milfam_wordpress_list_email_alias
transfer_community_connections
set_person_institution_column
transform_person_additionaldata_data
transfer_user_authentication_events_to_activities
transfer_user_profile_events_to_activities
transfer_admin_events_to_activities
transfer_activities_to_activities
associate_social_networks