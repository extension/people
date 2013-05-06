# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AccountSync < ActiveRecord::Base
  belongs_to :person
  attr_accessible :person, :person_id, :processed

  UPDATE_DATABASES = {'aae' => 'prod_aae',
                      'learn' => 'prod_learn'}

  after_create  :queue_update

  def queue_update
    #self.delay.update_accounts
    self.update_accounts
  end

  def update_accounts
    if(!self.processed?)
      UPDATE_DATABASES.keys.each do |sync_target|
        self.send(sync_target)
      end
      self.update_attributes({processed: true})
    end
  end

  def aae
    if(aae_user = AaeUser.find_by_darmok_id(self.person_id))
      self.connection.execute(aae_update_query)
    elsif(aae_user = AaeUser.find_by_email(self.person.email))
      self.connection.execute(aae_conversion_query)        
    else
      self.connection.execute(aae_insert_query)
    end
    self.connection.execute(aae_authmap_insert_query)
  end

  def learn
    if(learn_learner = LearnLearner.find_by_darmok_id(self.person_id))
      self.connection.execute(learn_update_query)
    elsif(learn_learner = LearnLearner.find_by_email(self.person.email))
      self.connection.execute(learn_conversion_query)        
    else
      self.connection.execute(learn_insert_query)
    end
    self.connection.execute(learn_authmap_insert_query)
  end

  def aae_update_query
    person = self.person
    update_database = UPDATE_DATABASES['aae']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.users
    SET #{update_database}.users.login        = #{quoted_value_or_null(person.idstring)}, 
        #{update_database}.users.first_name   = #{quoted_value_or_null(person.first_name)},
        #{update_database}.users.last_name    = #{quoted_value_or_null(person.last_name)},
        #{update_database}.users.retired      = #{value_or_null(person.retired)},
        #{update_database}.users.is_admin     = #{value_or_null(person.is_admin)},
        #{update_database}.users.email        = #{quoted_value_or_null(person.email)},
        #{update_database}.users.time_zone    = #{quoted_value_or_null(person.time_zone)},
        #{update_database}.users.location_id  = #{value_or_null(person.location_id)},
        #{update_database}.users.county_id    = #{value_or_null(person.county_id)},
        #{update_database}.users.title        = #{quoted_value_or_null(person.title)}
    WHERE #{update_database}.users.darmok_id = #{person.id}
    AND #{update_database}.users.kind = 'User'
    END_SQL
    query
  end

  def aae_conversion_query
    person = self.person
    update_database = UPDATE_DATABASES['aae']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.users
    SET #{update_database}.users.kind         = 'User',
        #{update_database}.users.darmok_id    = #{person.id},
        #{update_database}.users.login        = #{quoted_value_or_null(person.idstring)}, 
        #{update_database}.users.first_name   = #{quoted_value_or_null(person.first_name)},
        #{update_database}.users.last_name    = #{quoted_value_or_null(person.last_name)},
        #{update_database}.users.retired      = #{value_or_null(person.retired)},
        #{update_database}.users.is_admin     = #{value_or_null(person.is_admin)},
        #{update_database}.users.time_zone    = #{quoted_value_or_null(person.time_zone)},
        #{update_database}.users.location_id  = #{value_or_null(person.location_id)},
        #{update_database}.users.county_id    = #{value_or_null(person.county_id)},
        #{update_database}.users.title        = #{quoted_value_or_null(person.title)}
    WHERE #{update_database}.users.email = #{ActiveRecord::Base.quote_value(person.email)}
    AND #{update_database}.users.kind = 'PublicUser'
    END_SQL
    query
  end

  def self.aae_insert_query
    person = self.person
    update_database = UPDATE_DATABASES['aae']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.users (login, first_name, last_name, kind, email, time_zone, darmok_id, is_admin, location_id, county_id, title, created_at, updated_at)
    SELECT  #{quoted_value_or_null(person.idstring)}, 
            #{quoted_value_or_null(person.first_name)},
            #{quoted_value_or_null(person.last_name)},
            'User',
            #{quoted_value_or_null(person.email)},
            #{quoted_value_or_null(person.time_zone)},
            #{person.id},
            #{value_or_null(person.is_admin)},
            #{value_or_null(person.location_id)},
            #{value_or_null(person.county_id)},
            #{quoted_value_or_null(person.title)},
            #{quoted_value_or_null(person.created_at.to_s(:db))},
            NOW()
    END_SQL
    query
  end

  def aae_authmap_insert_query      
    person = self.person
    update_database = UPDATE_DATABASES['aae']
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

  def learn_update_query
    person = self.person
    update_database = UPDATE_DATABASES['learn']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.learners
    SET #{update_database}.learners.name         = #{quoted_value_or_null(person.fullname)},
        #{update_database}.learners.retired      = #{value_or_null(person.retired)},
        #{update_database}.learners.is_admin     = #{value_or_null(person.is_admin)},
        #{update_database}.learners.email        = #{quoted_value_or_null(person.email)},
        #{update_database}.learners.time_zone    = #{quoted_value_or_null(person.time_zone)}
    WHERE #{update_database}.learners.darmok_id = #{person.id}
    END_SQL
    query
  end

  def learn_conversion_query
    person = self.person
    update_database = UPDATE_DATABASES['learn']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{update_database}.learners
    SET #{update_database}.learners.name         = #{quoted_value_or_null(person.fullname)},
        #{update_database}.learners.retired      = #{value_or_null(person.retired)},
        #{update_database}.learners.is_admin     = #{value_or_null(person.is_admin)},
        #{update_database}.learners.email        = #{quoted_value_or_null(person.email)},
        #{update_database}.learners.time_zone    = #{quoted_value_or_null(person.time_zone)}
    WHERE #{update_database}.learners.email = #{ActiveRecord::Base.quote_value(person.email)}
    AND #{update_database}.learners.darmok_id IS NULL
    END_SQL
    query
  end

  def self.learn_insert_query
    person = self.person
    update_database = UPDATE_DATABASES['learn']
    query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{update_database}.learners (name, email, has_profile, time_zone, darmok_id, is_admin, created_at, updated_at) 
    SELECT  #{quoted_value_or_null(person.fullname)},
            #{quoted_value_or_null(person.email)},
            1,
            #{quoted_value_or_null(person.time_zone)},
            #{person.id},
            #{value_or_null(person.is_admin)},
            #{quoted_value_or_null(person.created_at.to_s(:db))},
            NOW()
    END_SQL
    query
  end

  def learn_authmap_insert_query      
    person = self.person
    update_database = UPDATE_DATABASES['learn']
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

  def value_or_null(value)
    value.blank? ? 'NULL' : value
  end

  def quoted_value_or_null(value)
    value.blank? ? 'NULL' : ActiveRecord::Base.quote_value(value)
  end


end