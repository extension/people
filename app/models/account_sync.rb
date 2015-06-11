# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AccountSync < ActiveRecord::Base
  serialize :errors
  attr_accessible :success, :errors, :person, :person_id, :processed, :process_on_create, :is_rename

  CREATE_ADMIN_ROLE = 3
  UPDATE_DATABASES = {'aae_database' => Settings.aae_database,
                      'learn_database' => Settings.learn_database,
                      'create_databases' => [Settings.create_database],
                      'www_database' => Settings.www_database,
                      'wordpress_databases' => [Settings.about_database, Settings.milfam_database]}

  belongs_to :person

  scope :not_processed, -> { where(processed: false)}

  def admin_application_label_for_wordpress_database(database)
    case database
    when Settings.about_database
      'about'
    when Settings.milfam_database
      'milfam'
    else
      nil
    end
  end

  def queue_update
    if(self.process_on_create or !Settings.redis_enabled)
      self.update_accounts
    else
      self.class.delay_for(5.seconds).delayed_update_accounts(self.id)
    end
  end

  def self.delayed_update_accounts(record_id)
    if(record = find_by_id(record_id))
      record.update_accounts
    end
  end

  def update_accounts
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

  def aae_database
    if(aae_user = AaeUser.find_by_darmok_id(self.person_id))
      self.connection.execute(aae_update_query)
    elsif(aae_user = AaeUser.find_by_email(self.person.email))
      self.connection.execute(aae_conversion_query)
    else
      self.connection.execute(aae_insert_query)
    end
    self.connection.execute(aae_authmap_insert_query)
    if(self.is_rename?)
      self.connection.execute(aae_authmap_delete_query)
    end

  end

  def learn_database
    if(learn_learner = LearnLearner.find_by_darmok_id(self.person_id))
      self.connection.execute(learn_update_query)
    elsif(learn_learner = LearnLearner.find_by_email(self.person.email))
      self.connection.execute(learn_conversion_query)
    else
      self.connection.execute(learn_insert_query)
    end
    self.connection.execute(learn_authmap_insert_query)
    if(self.is_rename?)
      self.connection.execute(learn_authmap_delete_query)
    end
  end

  def create_databases
    UPDATE_DATABASES['create_databases'].each do |update_database|
      self.connection.execute(create_insert_update_query(update_database))
      self.connection.execute(create_admin_roles_deletion_query(update_database))
      if(self.person.is_admin_for_application('create'))
        self.connection.execute(create_admin_roles_query(update_database))
      end
      ['first','last'].each do |name|
        ['data','revision'].each do |data_or_revision|
          self.connection.execute(create_names_update_query(update_database,name,data_or_revision))
        end
      end
      self.connection.execute(create_authmap_insert_query(update_database))
    end
  end

  def www_database
    self.connection.execute(www_insert_update_query)
  end

  def wordpress_databases
    UPDATE_DATABASES['wordpress_databases'].each do |update_database|
      self.connection.execute(wordpress_user_replace_query(update_database))
      self.connection.execute(wordpress_openid_replace_query(update_database))
      self.connection.execute(wordpress_usermeta_insert_update_query(update_database))
    end
  end


  def aae_update_query
    person = self.person
    update_database = UPDATE_DATABASES['aae_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.users
    SET #{update_database}.users.login                = #{quoted_value_or_null(person.idstring)},
        #{update_database}.users.first_name           = #{quoted_value_or_null(person.first_name)},
        #{update_database}.users.last_name            = #{quoted_value_or_null(person.last_name)},
        #{update_database}.users.retired              = #{person.retired},
        #{update_database}.users.is_admin             = #{person.is_admin_for_application('aae')},
        #{update_database}.users.email                = #{quoted_value_or_null(person.email)},
        #{update_database}.users.time_zone            = #{quoted_value_or_null(person.time_zone(false))},
        #{update_database}.users.location_id          = #{value_or_null(person.location_id)},
        #{update_database}.users.county_id            = #{value_or_null(person.county_id)},
        #{update_database}.users.title                = #{quoted_value_or_null(person.title)},
        #{update_database}.users.needs_search_update  = 1
    WHERE #{update_database}.users.darmok_id = #{person.id}
    AND #{update_database}.users.kind = 'User'
    END_SQL
    query
  end

  def aae_conversion_query
    person = self.person
    update_database = UPDATE_DATABASES['aae_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.users
    SET #{update_database}.users.kind                 = 'User',
        #{update_database}.users.darmok_id            = #{person.id},
        #{update_database}.users.login                = #{quoted_value_or_null(person.idstring)},
        #{update_database}.users.first_name           = #{quoted_value_or_null(person.first_name)},
        #{update_database}.users.last_name            = #{quoted_value_or_null(person.last_name)},
        #{update_database}.users.retired              = #{person.retired},
        #{update_database}.users.is_admin             = #{person.is_admin_for_application('aae')},
        #{update_database}.users.time_zone            = #{quoted_value_or_null(person.time_zone(false))},
        #{update_database}.users.location_id          = #{value_or_null(person.location_id)},
        #{update_database}.users.county_id            = #{value_or_null(person.county_id)},
        #{update_database}.users.title                = #{quoted_value_or_null(person.title)},
        #{update_database}.users.needs_search_update  = 1
    WHERE #{update_database}.users.email = #{ActiveRecord::Base.quote_value(person.email)}
    AND #{update_database}.users.kind = 'PublicUser'
    END_SQL
    query
  end

  def aae_insert_query
    person = self.person
    update_database = UPDATE_DATABASES['aae_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.users (login, first_name, last_name, kind, email, time_zone, darmok_id, is_admin, location_id, county_id, title, needs_search_update, created_at, updated_at)
    SELECT  #{quoted_value_or_null(person.idstring)},
            #{quoted_value_or_null(person.first_name)},
            #{quoted_value_or_null(person.last_name)},
            'User',
            #{quoted_value_or_null(person.email)},
            #{quoted_value_or_null(person.time_zone(false))},
            #{person.id},
            #{person.is_admin_for_application('aae')},
            #{value_or_null(person.location_id)},
            #{value_or_null(person.county_id)},
            #{quoted_value_or_null(person.title)},
            1,
            #{quoted_value_or_null(person.created_at.to_s(:db))},
            NOW()
    END_SQL
    query
  end

  def aae_authmap_insert_query
    person = self.person
    update_database = UPDATE_DATABASES['aae_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT IGNORE INTO #{update_database}.authmaps (user_id, authname, source, created_at, updated_at)
    SELECT #{update_database}.users.id,
           CONCAT('https://people.extension.org/',#{update_database}.users.login),
           'people',
           #{update_database}.users.created_at,
           NOW()
    FROM #{update_database}.users
    WHERE #{update_database}.users.darmok_id = #{person.id}
    END_SQL
    query
  end

  def aae_authmap_delete_query
    person = self.person
    update_database = UPDATE_DATABASES['aae_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    DELETE #{update_database}.authmaps.* FROM #{update_database}.authmaps,#{update_database}.users
    WHERE #{update_database}.authmaps.user_id = #{update_database}.users.id
          AND #{update_database}.authmaps.authname != CONCAT('https://people.extension.org/',#{update_database}.users.login)
          AND #{update_database}.authmaps.source = 'people'
          AND #{update_database}.users.darmok_id = #{person.id}
    END_SQL
    query
  end


  def learn_update_query
    person = self.person
    update_database = UPDATE_DATABASES['learn_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.learners
    SET #{update_database}.learners.name         = #{quoted_value_or_null(person.fullname)},
        #{update_database}.learners.retired      = #{person.retired},
        #{update_database}.learners.is_admin     = #{person.is_admin_for_application('learn')},
        #{update_database}.learners.email        = #{quoted_value_or_null(person.email)},
        #{update_database}.learners.time_zone    = #{quoted_value_or_null(person.time_zone(false))},
        #{update_database}.learners.needs_search_update  = 1
    WHERE #{update_database}.learners.darmok_id = #{person.id}
    END_SQL
    query
  end

  def learn_conversion_query
    person = self.person
    update_database = UPDATE_DATABASES['learn_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.learners
    SET #{update_database}.learners.name         = #{quoted_value_or_null(person.fullname)},
        #{update_database}.learners.retired      = #{person.retired},
        #{update_database}.learners.is_admin     = #{person.is_admin_for_application('learn')},
        #{update_database}.learners.email        = #{quoted_value_or_null(person.email)},
        #{update_database}.learners.time_zone    = #{quoted_value_or_null(person.time_zone(false))},
        #{update_database}.learners.needs_search_update  = 1
    WHERE #{update_database}.learners.email = #{ActiveRecord::Base.quote_value(person.email)}
    AND #{update_database}.learners.darmok_id IS NULL
    END_SQL
    query
  end

  def learn_insert_query
    person = self.person
    update_database = UPDATE_DATABASES['learn_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.learners (name, email, has_profile, time_zone, darmok_id, is_admin, needs_search_update, created_at, updated_at)
    SELECT  #{quoted_value_or_null(person.fullname)},
            #{quoted_value_or_null(person.email)},
            1,
            #{quoted_value_or_null(person.time_zone(false))},
            #{person.id},
            #{person.is_admin_for_application('learn')},
            1,
            #{quoted_value_or_null(person.created_at.to_s(:db))},
            NOW()
    END_SQL
    query
  end

  def learn_authmap_insert_query
    person = self.person
    update_database = UPDATE_DATABASES['learn_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT IGNORE INTO #{update_database}.authmaps (learner_id, authname, source, created_at, updated_at)
    SELECT #{update_database}.learners.id,
           CONCAT('https://people.extension.org/',#{ActiveRecord::Base.quote_value(person.idstring)}),
           'people',
           #{update_database}.learners.created_at,
           NOW()
    FROM #{update_database}.learners
    WHERE #{update_database}.learners.darmok_id = #{person.id}
    END_SQL
    query
  end

  def learn_authmap_delete_query
    person = self.person
    update_database = UPDATE_DATABASES['learn_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    DELETE #{update_database}.authmaps.* FROM #{update_database}.authmaps,#{update_database}.learners
    WHERE #{update_database}.authmaps.learner_id = #{update_database}.learners.id
          AND #{update_database}.authmaps.authname != CONCAT('https://people.extension.org/',#{ActiveRecord::Base.quote_value(person.idstring)})
          AND #{update_database}.authmaps.source = 'people'
          AND #{update_database}.learners.darmok_id = #{person.id}
    END_SQL
    query
  end


  def create_insert_update_query(update_database)
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.users (uid,name,pass,mail,created,status)
    SELECT  #{person.id},
            #{quoted_value_or_null(person.idstring)},
            #{ActiveRecord::Base.quote_value(Settings.create_password_string)},
            #{quoted_value_or_null(person.email)},
            UNIX_TIMESTAMP('#{person.created_at.to_s(:db)}'),
            #{(person.validaccount? ? 1 : 0)}
    ON DUPLICATE KEY
    UPDATE name=#{quoted_value_or_null(person.idstring)},
           pass=#{ActiveRecord::Base.quote_value(Settings.create_password_string)},
           mail=#{quoted_value_or_null(person.email)},
           status=#{(person.validaccount? ? 1 : 0)},
           created=UNIX_TIMESTAMP('#{person.created_at.to_s(:db)}')
    END_SQL
    query
  end


  def create_admin_roles_deletion_query(update_database)
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    DELETE FROM #{update_database}.users_roles
    WHERE uid = #{person.id} AND rid = #{CREATE_ADMIN_ROLE}
    END_SQL
    query
  end

  def create_admin_roles_query(update_database)
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.users_roles (uid,rid)
    SELECT  #{person.id},
            #{CREATE_ADMIN_ROLE}
    END_SQL
    query
  end

  def create_names_update_query(update_database,name,data_or_revision)
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.field_#{data_or_revision}_field_#{name}_name (entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_#{name}_name_value, field_#{name}_name_format)
    SELECT 'user',
           'user',
           0,
           #{person.id},
           #{person.id},
           'und',
           0,
           #{quoted_value_or_null(person.send("#{name}_name"))},
           'NULL'
    ON DUPLICATE KEY
    UPDATE field_#{name}_name_value=#{quoted_value_or_null(person.send("#{name}_name"))}
    END_SQL
    query
  end

  def create_authmap_insert_query(update_database)
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.authmap (aid,uid,authname,module)
    SELECT #{person.id},
           #{person.id},
           CONCAT('https://people.extension.org/',#{ActiveRecord::Base.quote_value(person.idstring)}),
           'openid'
    ON DUPLICATE KEY
    UPDATE uid=#{person.id},
           authname=CONCAT('https://people.extension.org/',#{ActiveRecord::Base.quote_value(person.idstring)})
    END_SQL
    query
  end


  def www_insert_update_query
    person = self.person
    update_database = UPDATE_DATABASES['www_database']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.people (id,uid,first_name,last_name,is_admin,retired,created_at,updated_at)
    SELECT  #{person.id},
            #{ActiveRecord::Base.quote_value(person.openid_url)},
            #{quoted_value_or_null(person.first_name)},
            #{quoted_value_or_null(person.last_name)},
            #{person.retired},
            #{person.is_admin_for_application('www')},
            #{ActiveRecord::Base.quote_value(person.created_at.to_s(:db))},
            #{ActiveRecord::Base.quote_value(person.updated_at.to_s(:db))}
    ON DUPLICATE KEY
    UPDATE uid=#{ActiveRecord::Base.quote_value(person.openid_url)},
           first_name=#{quoted_value_or_null(person.first_name)},
           last_name=#{quoted_value_or_null(person.last_name)},
           retired=#{person.retired},
           is_admin=#{person.is_admin_for_application('www')},
           updated_at=NOW()
    END_SQL
    query
  end

  def wordpress_user_replace_query(update_database)
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    REPLACE INTO #{update_database}.wp_users (id,user_login,user_pass,user_email,user_nicename,display_name)
    SELECT #{person.id},
           #{ActiveRecord::Base.quote_value(person.idstring)},
           #{ActiveRecord::Base.quote_value(Settings.create_password_string)},
           #{quoted_value_or_null(person.email)},
           #{ActiveRecord::Base.quote_value(person.idstring)},
           #{ActiveRecord::Base.quote_value(person.fullname)}
    END_SQL
    query
  end

  def wordpress_openid_replace_query(update_database)
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    REPLACE INTO #{update_database}.wp_openid_identities (uurl_id,user_id,url)
    SELECT #{person.id},
           #{person.id},
           #{ActiveRecord::Base.quote_value(person.openid_url)}
    END_SQL
    query
  end

  def wordpress_usermeta_insert_update_query(update_database)
    admin_label = self.admin_application_label_for_wordpress_database(update_database)
    person = self.person
    if(person.retired?)
      capability_string = PHP.serialize({})
    elsif(admin_label and person.is_admin_for_application(admin_label))
      capability_string = PHP.serialize({"administrator"=>true})
    else
      capability_string = PHP.serialize({"editor"=>true})
    end

    # does a row exist? then update, else insert
    result = self.connection.execute("SELECT * from #{update_database}.wp_usermeta WHERE user_id = #{person.id} and meta_key = 'wp_capabilities'")
    if(result.first.blank?)
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT INTO #{update_database}.wp_usermeta (user_id,meta_key,meta_value)
      SELECT #{person.id},
             'wp_capabilities',
             #{ActiveRecord::Base.quote_value(capability_string)}
      END_SQL

    else
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      UPDATE #{update_database}.wp_usermeta
      SET meta_value = #{ActiveRecord::Base.quote_value(capability_string)}
      WHERE user_id = #{person.id} AND meta_key = 'wp_capabilities'
      END_SQL
    end
    query
  end

  def value_or_null(value)
    value.blank? ? 'NULL' : value
  end


  def quoted_value_or_null(value)
    value.blank? ? 'NULL' : ActiveRecord::Base.quote_value(value)
  end


end
