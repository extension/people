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

  belongs_to :person
  after_create  :queue_update

  scope :not_processed, -> { where(processed: false)}
  scope :has_error, -> { where(success: false)}

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
        Site.all.each do |site|
          sync_method = "sync_#{site.label}"
          self.send(sync_method,site)
        end
        self.update_attributes({processed: true, success: true})
      rescue StandardError => e
        Honeybadger.notify(e)
        self.update_attributes({processed: true, success: false, errors: e.message})
      end
    end
  end

  def sync_ask(site)
    update_database = site.sync_database
    if(ask_user = AskUser.find_by_darmok_id(self.person_id))
      self.connection.execute(ask_update_query(site))
    elsif(ask_user = AskUser.find_by_email(self.person.display_email))
      self.connection.execute(ask_conversion_query(site))
    else
      self.connection.execute(ask_insert_query(site))
    end
  end

  def sync_learn(site)
    update_database = site.sync_database
    if(learn_learner = LearnLearner.find_by_darmok_id(self.person_id))
      self.connection.execute(learn_update_query(site))
    elsif(learn_learner = LearnLearner.find_by_email(self.person.display_email))
      learn_learner.update_column(:darmok_id, self.person.id)
      self.connection.execute(learn_update_query(site))
    else
      self.connection.execute(learn_insert_query(site))
    end
  end

  def sync_create(site)
    update_database = site.sync_database
    self.connection.execute(create_insert_update_query(site))
    self.connection.execute(create_admin_roles_deletion_query(site))
    if(self.person.is_admin_for_site(site))
      self.connection.execute(create_admin_roles_query(site))
    end
    ['first','last'].each do |name|
      ['data','revision'].each do |data_or_revision|
        self.connection.execute(create_names_update_query(site,name,data_or_revision))
      end
    end
    self.connection.execute(create_authmap_insert_query(site))
  end

  def sync_articles(site)
    update_database = site.sync_database
    self.connection.execute(www_insert_update_query(site))
  end

  def sync_homepage(site)
    update_database = site.sync_database
    self.connection.execute(wordpress_user_replace_query(site))
    self.connection.execute(wordpress_openid_replace_query(site))
    self.connection.execute(wordpress_usermeta_role_insert_update_query(site))
    self.connection.execute(wordpress_usermeta_userlevel_insert_update_query(site))
    self.connection.execute(wordpress_usermeta_ghostpost_insert_update_query(site))
    self.connection.execute(wordpress_usermeta_wysiwyg_insert_query(site))
  end

  def ask_update_query(site)
    update_database = site.sync_database
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.users
    SET #{update_database}.users.login                = #{quoted_value_or_null(person.idstring)},
        #{update_database}.users.openid               = CONCAT('https://people.extension.org/',#{quoted_value_or_null(person.idstring)}),
        #{update_database}.users.first_name           = #{quoted_value_or_null(person.first_name)},
        #{update_database}.users.last_name            = #{quoted_value_or_null(person.last_name)},
        #{update_database}.users.unavailable          = #{(person.unavailable? ? 1 : 0)},
        #{update_database}.users.unavailable_reason   = #{value_or_null(person.unavailable_reason)},
        #{update_database}.users.is_admin             = #{person.is_admin_for_site(site)},
        #{update_database}.users.email                = #{quoted_value_or_null(person.display_email)},
        #{update_database}.users.time_zone            = #{quoted_value_or_null(person.time_zone(false))},
        #{update_database}.users.location_id          = #{value_or_null(person.location_id)},
        #{update_database}.users.county_id            = #{value_or_null(person.county_id)},
        #{update_database}.users.institution_id       = #{value_or_null(person.institution_id)},
        #{update_database}.users.title                = #{quoted_value_or_null(person.title)},
        #{update_database}.users.needs_search_update  = 1
    WHERE #{update_database}.users.darmok_id = #{person.id}
    AND #{update_database}.users.kind = 'User'
    END_SQL
    query
  end

  def ask_conversion_query(site)
    update_database = site.sync_database
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.users
    SET #{update_database}.users.kind                 = 'User',
        #{update_database}.users.darmok_id            = #{person.id},
        #{update_database}.users.login                = #{quoted_value_or_null(person.idstring)},
        #{update_database}.users.openid               = CONCAT('https://people.extension.org/',#{quoted_value_or_null(person.idstring)}),
        #{update_database}.users.first_name           = #{quoted_value_or_null(person.first_name)},
        #{update_database}.users.last_name            = #{quoted_value_or_null(person.last_name)},
        #{update_database}.users.unavailable          = #{(person.unavailable? ? 1 : 0)},
        #{update_database}.users.unavailable_reason   = #{value_or_null(person.unavailable_reason)},
        #{update_database}.users.is_admin             = #{person.is_admin_for_site(site)},
        #{update_database}.users.time_zone            = #{quoted_value_or_null(person.time_zone(false))},
        #{update_database}.users.location_id          = #{value_or_null(person.location_id)},
        #{update_database}.users.county_id            = #{value_or_null(person.county_id)},
        #{update_database}.users.institution_id       = #{value_or_null(person.institution_id)},
        #{update_database}.users.title                = #{quoted_value_or_null(person.title)},
        #{update_database}.users.needs_search_update  = 1
    WHERE #{update_database}.users.email = #{ActiveRecord::Base.quote_value(person.display_email)}
    AND #{update_database}.users.kind = 'PublicUser'
    END_SQL
    query
  end

  def ask_insert_query(site)
    update_database = site.sync_database
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.users (login, openid, first_name, last_name, kind, email, time_zone,
                                          darmok_id, is_admin, location_id, county_id, institution_id,
                                          title, unavailable, unavailable_reason, needs_search_update, created_at, updated_at)
    SELECT  #{quoted_value_or_null(person.idstring)},
            CONCAT('https://people.extension.org/',#{quoted_value_or_null(person.idstring)}),
            #{quoted_value_or_null(person.first_name)},
            #{quoted_value_or_null(person.last_name)},
            'User',
            #{quoted_value_or_null(person.display_email)},
            #{quoted_value_or_null(person.time_zone(false))},
            #{person.id},
            #{person.is_admin_for_site(site)},
            #{value_or_null(person.location_id)},
            #{value_or_null(person.county_id)},
            #{value_or_null(person.institution_id)},
            #{quoted_value_or_null(person.title)},
            #{(person.unavailable? ? 1 : 0)},
            #{value_or_null(person.unavailable_reason)},
            1,
            #{quoted_value_or_null(person.created_at.to_s(:db))},
            NOW()
    END_SQL
    query
  end

  def learn_update_query(site)
    update_database = site.sync_database
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.learners
    SET #{update_database}.learners.name           = #{quoted_value_or_null(person.fullname)},
        #{update_database}.learners.openid         = CONCAT('https://people.extension.org/',#{quoted_value_or_null(person.idstring)}),
        #{update_database}.learners.institution_id = #{value_or_null(person.institution_id)},
        #{update_database}.learners.retired        = #{person.retired},
        #{update_database}.learners.is_admin       = #{person.is_admin_for_site(site)},
        #{update_database}.learners.email          = #{quoted_value_or_null(person.display_email)},
        #{update_database}.learners.time_zone      = #{quoted_value_or_null(person.time_zone(false))},
        #{update_database}.learners.needs_search_update  = 1
    WHERE #{update_database}.learners.darmok_id = #{person.id}
    END_SQL
    query
  end

  def learn_insert_query(site)
    update_database = site.sync_database
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.learners (name, openid, institution_id, email, has_profile, time_zone, darmok_id, is_admin, needs_search_update, created_at, updated_at)
    SELECT  #{quoted_value_or_null(person.fullname)},
            CONCAT('https://people.extension.org/',#{ActiveRecord::Base.quote_value(person.idstring)}),
            #{value_or_null(person.institution_id)},
            #{quoted_value_or_null(person.display_email)},
            1,
            #{quoted_value_or_null(person.time_zone(false))},
            #{person.id},
            #{person.is_admin_for_site(site)},
            1,
            #{quoted_value_or_null(person.created_at.to_s(:db))},
            NOW()
    END_SQL
    query
  end

  def create_insert_update_query(site)
    update_database = site.sync_database
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.users (uid,name,pass,mail,created,status)
    SELECT  #{person.id},
            #{quoted_value_or_null(person.idstring)},
            #{ActiveRecord::Base.quote_value(Settings.create_password_string)},
            #{quoted_value_or_null(person.display_email)},
            UNIX_TIMESTAMP('#{person.created_at.to_s(:db)}'),
            #{(person.validaccount? ? 1 : 0)}
    ON DUPLICATE KEY
    UPDATE name=#{quoted_value_or_null(person.idstring)},
           pass=#{ActiveRecord::Base.quote_value(Settings.create_password_string)},
           mail=#{quoted_value_or_null(person.display_email)},
           status=#{(person.validaccount? ? 1 : 0)},
           created=UNIX_TIMESTAMP('#{person.created_at.to_s(:db)}')
    END_SQL
    query
  end


  def create_admin_roles_deletion_query(site)
    update_database = site.sync_database
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    DELETE FROM #{update_database}.users_roles
    WHERE uid = #{person.id} AND rid = #{CREATE_ADMIN_ROLE}
    END_SQL
    query
  end

  def create_admin_roles_query(site)
    update_database = site.sync_database
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.users_roles (uid,rid)
    SELECT  #{person.id},
            #{CREATE_ADMIN_ROLE}
    END_SQL
    query
  end

  def create_names_update_query(site,name,data_or_revision)
    update_database = site.sync_database
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

  def create_authmap_insert_query(site)
    update_database = site.sync_database
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


  def www_insert_update_query(site)
    update_database = site.sync_database
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.people (id,uid,first_name,last_name,is_admin,retired,created_at,updated_at)
    SELECT  #{person.id},
            #{ActiveRecord::Base.quote_value(person.openid_url)},
            #{quoted_value_or_null(person.first_name)},
            #{quoted_value_or_null(person.last_name)},
            #{person.retired},
            #{person.is_admin_for_site(site)},
            #{ActiveRecord::Base.quote_value(person.created_at.to_s(:db))},
            #{ActiveRecord::Base.quote_value(person.updated_at.to_s(:db))}
    ON DUPLICATE KEY
    UPDATE uid=#{ActiveRecord::Base.quote_value(person.openid_url)},
           first_name=#{quoted_value_or_null(person.first_name)},
           last_name=#{quoted_value_or_null(person.last_name)},
           retired=#{person.retired},
           is_admin=#{person.is_admin_for_site(site)},
           updated_at=NOW()
    END_SQL
    query
  end

  def wordpress_user_replace_query(site)
    update_database = site.sync_database
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    REPLACE INTO #{update_database}.wp_users (id,user_login,user_pass,user_email,user_nicename,display_name)
    SELECT #{person.id},
           #{ActiveRecord::Base.quote_value(person.idstring)},
           #{ActiveRecord::Base.quote_value(Settings.create_password_string)},
           #{quoted_value_or_null(person.display_email)},
           #{ActiveRecord::Base.quote_value(person.idstring)},
           #{ActiveRecord::Base.quote_value(person.fullname)}
    END_SQL
    query
  end

  def wordpress_openid_replace_query(site)
    update_database = site.sync_database
    person = self.person
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    REPLACE INTO #{update_database}.wp_openid_identities (uurl_id,user_id,url)
    SELECT #{person.id},
           #{person.id},
           #{ActiveRecord::Base.quote_value(person.openid_url)}
    END_SQL
    query
  end

  def wordpress_usermeta_role_insert_update_query(site)
    update_database = site.sync_database
    person = self.person
    if(person.retired?)
      capability_string = PHP.serialize({})
    else
      role = SiteRole.wordpress_label(person.role_for_site(site))
      capability_string = PHP.serialize({"#{role}"=>true})
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

  def wordpress_usermeta_userlevel_insert_update_query(site)
    update_database = site.sync_database
    person = self.person
    if(person.retired?)
      userlevel = 0
    else
      userlevel = SiteRole.wordpress_user_level(person.role_for_site(site))
    end

    # does a row exist? then update, else insert
    result = self.connection.execute("SELECT * from #{update_database}.wp_usermeta WHERE user_id = #{person.id} and meta_key = 'wp_user_level'")
    if(result.first.blank?)
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT INTO #{update_database}.wp_usermeta (user_id,meta_key,meta_value)
      SELECT #{person.id},
             'wp_user_level',
             #{userlevel}
      END_SQL

    else
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      UPDATE #{update_database}.wp_usermeta
      SET meta_value = #{userlevel}
      WHERE user_id = #{person.id} AND meta_key = 'wp_user_level'
      END_SQL
    end
    query
  end

  def wordpress_usermeta_ghostpost_insert_update_query(site)
    update_database = site.sync_database
    person = self.person
    if(person.retired?)
      ghostpost = '0'
    else
      ghostpost = (person.proxy_writer_for_site?(site) ? '1' : '0')
    end

    # does a row exist? then update, else insert
    result = self.connection.execute("SELECT * from #{update_database}.wp_usermeta WHERE user_id = #{person.id} and meta_key = 'allow_ghost_post'")
    if(result.first.blank?)
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT INTO #{update_database}.wp_usermeta (user_id,meta_key,meta_value)
      SELECT #{person.id},
             'allow_ghost_post',
             #{ActiveRecord::Base.quote_value(ghostpost)}
      END_SQL

    else
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      UPDATE #{update_database}.wp_usermeta
      SET meta_value = #{ActiveRecord::Base.quote_value(ghostpost)}
      WHERE user_id = #{person.id} AND meta_key = 'allow_ghost_post'
      END_SQL
    end
    query
  end



  def wordpress_usermeta_wysiwyg_insert_query(site)
    update_database = site.sync_database
    person = self.person
    # does a row exist? then ignore, else insert
    result = self.connection.execute("SELECT * from #{update_database}.wp_usermeta WHERE user_id = #{person.id} and meta_key = 'rich_editing'")
    query = "SELECT 1;"
    if(result.first.blank?)
      query = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT INTO #{update_database}.wp_usermeta (user_id,meta_key,meta_value)
      SELECT #{person.id},
             'rich_editing',
             'true'
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

  def self.clear_out_old_records
    record_count = self.where("created_at < ?",Time.now - Settings.cleanup_months.months).count
    self.delete_all(["created_at < ?",Time.now - Settings.cleanup_months.months])
    record_count
  end

end
