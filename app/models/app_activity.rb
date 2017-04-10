# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AppActivity < ActiveRecord::Base
  serialize :additionaldata

  # tracked applications
  APP_ARTICLES  = 100
  APP_ASK       = 200
  APP_PUBLISH   = 300
  APP_CREATE    = 400
  APP_HOMEPAGE  = 500
  APP_LEARN     = 600
  APP_MILFAM    = 700
  APP_PEOPLE    = 800

  # source types
  APP_PUBLISH_POSTS = 301
  APP_PUBLISH_COMMENTS = 302

  APP_HOMEPAGE_POSTS = 301
  APP_HOMEPAGE_COMMENTS = 302

  APP_LEARN_EVENT_ACTIVITY = 601
  APP_LEARN_VERSIONS = 602

  APP_CREATE_REVISIONS = 401
  APP_CREATE_WORKFLOW_EVENTS = 402
  APP_CREATE_COMMENTS = 403

  APP_ASK_QUESTIONEVENTS = 201

  # APP_PEOPLE_ACTIVITY    = 801


  # tracked application labels
  APP_LABELS = {
    APP_ARTICLES => 'articles',
    APP_ASK => 'ask',
    APP_CREATE => 'create',
    APP_HOMEPAGE => 'homepage',
    APP_LEARN => 'learn',
    APP_MILFAM => 'milfam',
    APP_PEOPLE => 'people',
    APP_PUBLISH => 'publish'
  }

  # activities
  ACTIVITY_OTHER = 1
  ACTIVITY_EDIT = 2
  ACTIVITY_COMMENT = 3
  ACTIVITY_BOOKMARK = 4
  ACTIVITY_ATTEND = 5
  ACTIVITY_WATCH = 6
  ACTIVITY_REVIEW = 7
  ACTIVITY_PUBLISH = 8
  ACTIVITY_WORKFLOW = 9
  ACTIVITY_ANSWER = 10
  ACTIVITY_HANDLED = 11
  # ACTIVITY_LOGIN = 12
  # ACTIVITY_PROFILE = 13
  # ACTIVITY_COLLEAGUE_PROFILE = 14
  # ACTIVITY_GROUP = 15


  ACTIVITY_LABELS = {
    ACTIVITY_OTHER => 'other activity',
    ACTIVITY_EDIT => 'edit',
    ACTIVITY_COMMENT => 'comment',
    ACTIVITY_BOOKMARK => 'bookmark',
    ACTIVITY_ATTEND => 'attend',
    ACTIVITY_WATCH => 'watch',
    ACTIVITY_REVIEW => 'review',
    ACTIVITY_PUBLISH => 'publish',
    ACTIVITY_WORKFLOW => 'workflow',
    ACTIVITY_ANSWER => 'answer',
    ACTIVITY_HANDLED => 'handled'
    # ACTIVITY_LOGIN => 'login',
    # ACTIVITY_PROFILE => 'profile',
    # ACTIVITY_COLLEAGUE_PROFILE => 'colleague profile',
    # ACTIVITY_GROUP => 'group'
  }

  def self.publish_post_activity_import
    PublishSite.order(:blog_id).each do |publish_site|
      publish_site_id = publish_site.blog_id
      publish_site_name = publish_site.path.gsub('/','')
      publish_site_name = 'root' if(publish_site_name.blank?)

      # edits
      postcount = PublishSitePost.repoint(publish_site_id)
      database_name = PublishSitePost.connection.current_database
      next if(postcount.nil? or postcount == 0)
      next if(PublishSitePost.activity_entries.count == 0)
      insert_values = []
      PublishSitePost.includes(:publish_user => :publish_openid).activity_entries.each do |posting|
        next if !(user = posting.publish_user)
        next if !(openid = user.publish_openid)
        # the core app item is the "post" at a table level, bit shifted due to multiple tables
        item_id = (posting.post_parent != 0 ? posting.post_parent : posting.ID)
        app_item_id = (( publish_site_id << 24 ) | item_id)
        source_id = posting.ID
        insert_list = []
        insert_list << posting.post_author # person_id
        insert_list << APP_PUBLISH # app_id
        insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_PUBLISH])  # app_label
        insert_list << APP_PUBLISH_POSTS # app_source_type
        insert_list << publish_site_id # section_id
        insert_list << ActiveRecord::Base.quote_value(publish_site_name)  # section_label
        insert_list << ACTIVITY_EDIT # activity_code
        insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[ACTIVITY_EDIT]) # activity_label
        insert_list << app_item_id # app_item_id
        insert_list << posting.ID # source_id
        insert_list << ActiveRecord::Base.quote_value('PublishSitePost') # source_model
        insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{PublishSitePost.table_name}") # source_table
        # fingerprint = person_id:app_id:section_id:activity_code:item_fingerprint:activity_at
        fingerprint_builder = []
        fingerprint_builder << posting.post_author
        fingerprint_builder << APP_PUBLISH
        fingerprint_builder << publish_site_id
        fingerprint_builder << ACTIVITY_EDIT
        fingerprint_builder << (( publish_site_id << 24 ) | source_id )
        fingerprint_builder << 'PublishSitePost'
        fingerprint_builder << posting.post_date.to_s
        fingerprint = Digest::SHA1.hexdigest("#{fingerprint_builder.join(':')}")
        insert_list << ActiveRecord::Base.quote_value(fingerprint) # fingerprint
        insert_list << ActiveRecord::Base.quote_value(posting.post_date.to_s(:db)) # activity_at
        insert_list << ActiveRecord::Base.quote_value(Time.zone.now.to_s(:db)) # created_at
        insert_values << "(#{insert_list.join(',')})"
      end

      if(insert_values.size > 0)
        insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
        INSERT IGNORE INTO #{self.table_name}
        (person_id,app_id,app_label,app_source_type,
         section_id,section_label,activity_code,activity_label,
         app_item_id,source_id,source_model,source_table,
         fingerprint,activity_at,created_at)
        VALUES #{insert_values.join(',')};
        END_SQL
        self.connection.execute(insert_sql)
      end

    end # publish site list
  end  # publish data import

  def self.publish_comment_activity_import

    PublishSite.order(:blog_id).each do |publish_site|
      publish_site_id = publish_site.blog_id
      publish_site_name = publish_site.path.gsub('/','')
      publish_site_name = 'root' if(publish_site_name.blank?)

      commentcount = PublishSiteComment.repoint(publish_site_id)
      database_name = PublishSiteComment.connection.current_database
      next if(commentcount.nil? or commentcount == 0)
      next if (PublishSiteComment.user_activities.count == 0)
      insert_values = []
      PublishSiteComment.includes(:publish_user => :publish_openid).user_activities.each do |comment|
        next if !(user = comment.publish_user)
        next if !(openid = user.publish_openid)
        # the core app item is the "post" at a table level, bit shifted due to multiple tables
        item_id = comment.comment_post_ID
        app_item_id = (( publish_site_id << 24 ) | item_id)
        source_id = comment.comment_ID
        insert_list = []
        insert_list << comment.user_id # person_id
        insert_list << APP_PUBLISH # app_id
        insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_PUBLISH])  # app_label
        insert_list << APP_PUBLISH_COMMENTS # app_source_type
        insert_list << publish_site_id # section_id
        insert_list << ActiveRecord::Base.quote_value(publish_site_name)  # section_label
        insert_list << ACTIVITY_COMMENT # activity_code
        insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[ACTIVITY_COMMENT]) # activity_label
        insert_list << app_item_id # app_item_id
        insert_list << source_id # source_id
        insert_list << ActiveRecord::Base.quote_value('PublishSiteComment') # source_model
        insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{PublishSiteComment.table_name}") # source_table
        # fingerprint = person_id:app_id:section_id:activity_code:item_fingerprint:activity_at
        fingerprint_builder = []
        fingerprint_builder << comment.user_id
        fingerprint_builder << APP_PUBLISH
        fingerprint_builder << publish_site_id
        fingerprint_builder << ACTIVITY_COMMENT
        fingerprint_builder << (( publish_site_id << 24 ) | source_id )
        fingerprint_builder << 'PublishSiteComment'
        fingerprint_builder << comment.comment_date.to_s
        fingerprint = Digest::SHA1.hexdigest("#{fingerprint_builder.join(':')}")
        insert_list << ActiveRecord::Base.quote_value(fingerprint) # fingerprint
        insert_list << ActiveRecord::Base.quote_value(comment.comment_date.to_s(:db)) # activity_at
        insert_list << ActiveRecord::Base.quote_value(Time.zone.now.to_s(:db)) # created_at
        insert_values << "(#{insert_list.join(',')})"
      end

      if(insert_values.size > 0)
        insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
        INSERT IGNORE INTO #{self.table_name}
        (person_id,app_id,app_label,app_source_type,
         section_id,section_label,activity_code,activity_label,
         app_item_id,source_id,source_model,source_table,
         fingerprint,activity_at,created_at)
        VALUES #{insert_values.join(',')};
        END_SQL
        self.connection.execute(insert_sql)
      end
    end # publish site list
  end  # publish data import

  def self.homepage_post_activity_import
    # edits
    database_name = HomepagePost.connection.current_database
    insert_values = []
    HomepagePost.includes(:homepage_user).activity_entries.each do |posting|
      next if !(user = posting.homepage_user)
      # the core app item is the "post" at a table level
      item_id = (posting.post_parent != 0 ? posting.post_parent : posting.ID)
      app_item_id = item_id
      source_id = posting.ID
      insert_list = []
      insert_list << posting.post_author # person_id
      insert_list << APP_HOMEPAGE # app_id
      insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_HOMEPAGE])  # app_label
      insert_list << APP_HOMEPAGE_POSTS # app_source_type
      insert_list << ACTIVITY_EDIT # activity_code
      insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[ACTIVITY_EDIT]) # activity_label
      insert_list << app_item_id # app_item_id
      insert_list << posting.ID # source_id
      insert_list << ActiveRecord::Base.quote_value('HomepagePost') # source_model
      insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{HomepagePost.table_name}") # source_table
      # fingerprint = person_id:app_id:section_id:activity_code:item_fingerprint:activity_at
      fingerprint_builder = []
      fingerprint_builder << posting.post_author
      fingerprint_builder << APP_HOMEPAGE
      fingerprint_builder << ACTIVITY_EDIT
      fingerprint_builder << source_id
      fingerprint_builder << 'HomepagePost'
      fingerprint_builder << posting.post_date.to_s
      fingerprint = Digest::SHA1.hexdigest("#{fingerprint_builder.join(':')}")
      insert_list << ActiveRecord::Base.quote_value(fingerprint) # fingerprint
      insert_list << ActiveRecord::Base.quote_value(posting.post_date.to_s(:db)) # activity_at
      insert_list << ActiveRecord::Base.quote_value(Time.zone.now.to_s(:db)) # created_at
      insert_values << "(#{insert_list.join(',')})"
    end

    if(insert_values.size > 0)
      insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT IGNORE INTO #{self.table_name}
      (person_id,app_id,app_label,app_source_type,
       activity_code,activity_label,
       app_item_id,source_id,source_model,source_table,
       fingerprint,activity_at,created_at)
      VALUES #{insert_values.join(',')};
      END_SQL
      self.connection.execute(insert_sql)
    end
  end

  def self.homepage_comment_activity_import
    database_name = HomepageComment.connection.current_database
    insert_values = []
    HomepageComment.includes(:homepage_user).user_activities.each do |comment|
      next if !(user = comment.homepage_user)
      # the core app item is the "post" at a table level, bit shifted due to multiple tables
      item_id = comment.comment_post_ID
      app_item_id = item_id
      source_id = comment.comment_ID
      insert_list = []
      insert_list << comment.user_id # person_id
      insert_list << APP_HOMEPAGE # app_id
      insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_HOMEPAGE])  # app_label
      insert_list << APP_HOMEPAGE_COMMENTS # app_source_type
      insert_list << ACTIVITY_COMMENT # activity_code
      insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[ACTIVITY_COMMENT]) # activity_label
      insert_list << app_item_id # app_item_id
      insert_list << source_id # source_id
      insert_list << ActiveRecord::Base.quote_value('HomepageComment') # source_model
      insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{HomepageComment.table_name}") # source_table
      # fingerprint = person_id:app_id:section_id:activity_code:item_fingerprint:activity_at
      fingerprint_builder = []
      fingerprint_builder << comment.user_id
      fingerprint_builder << APP_HOMEPAGE
      fingerprint_builder << ACTIVITY_COMMENT
      fingerprint_builder << source_id
      fingerprint_builder << 'HomepageComment'
      fingerprint_builder << comment.comment_date.to_s
      fingerprint = Digest::SHA1.hexdigest("#{fingerprint_builder.join(':')}")
      insert_list << ActiveRecord::Base.quote_value(fingerprint) # fingerprint
      insert_list << ActiveRecord::Base.quote_value(comment.comment_date.to_s(:db)) # activity_at
      insert_list << ActiveRecord::Base.quote_value(Time.zone.now.to_s(:db)) # created_at
      insert_values << "(#{insert_list.join(',')})"
    end

    if(insert_values.size > 0)
      insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT IGNORE INTO #{self.table_name}
      (person_id,app_id,app_label,app_source_type,
       activity_code,activity_label,
       app_item_id,source_id,source_model,source_table,
       fingerprint,activity_at,created_at)
      VALUES #{insert_values.join(',')};
      END_SQL
      self.connection.execute(insert_sql)
    end
  end  # homepage data import

  def self.learn_activity_to_activity_code(learn_activity)
    case learn_activity
    when LearnEventActivity::ANSWER
      ACTIVITY_OTHER
    when LearnEventActivity::RATING
      ACTIVITY_OTHER
    when LearnEventActivity::RATING_ON_COMMENT
      ACTIVITY_OTHER
    when LearnEventActivity::COMMENT
      ACTIVITY_COMMENT
    when LearnEventActivity::COMMENT_ON_COMMENT
      ACTIVITY_COMMENT
    when LearnEventActivity::CONNECT_BOOKMARK
      ACTIVITY_BOOKMARK
    when LearnEventActivity::CONNECT_ATTEND
      ACTIVITY_ATTEND
    when LearnEventActivity::CONNECT_WATCH
      ACTIVITY_WATCH
    else
      ACTIVITY_OTHER
    end
  end

  def self.learn_event_activity_import
    # learn event activity
    database_name = LearnEventActivity.connection.current_database
    LearnEventActivity.includes(:learner).where("activity IN (#{LearnEventActivity::TRANSFERRED_ACTIVITY.join(',')})").find_in_batches do |group|
      insert_values = []
      group.each do |activity|
        next if !(learner = activity.learner)
        next if learner.darmok_id.blank?
        # the core app item is the event
        app_item_id = activity.event_id
        source_id = activity.id
        insert_list = []
        insert_list << learner.darmok_id # person_id
        insert_list << APP_LEARN # app_id
        insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_LEARN])  # app_label
        insert_list << APP_LEARN_EVENT_ACTIVITY # app_source_type
        activity_code = self.learn_activity_to_activity_code(activity.activity)
        insert_list << activity_code # activity_code
        insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[activity_code]) # activity_label
        insert_list << app_item_id # app_item_id
        insert_list << source_id # source_id
        insert_list << ActiveRecord::Base.quote_value('LearnEventActivity') # source_model
        insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{LearnEventActivity.table_name}") # source_table
        fingerprint_builder = []
        fingerprint_builder << learner.darmok_id
        fingerprint_builder << APP_LEARN
        fingerprint_builder << activity_code
        fingerprint_builder << source_id
        fingerprint_builder << 'LearnEventActivity'
        fingerprint_builder << activity.updated_at.to_s
        fingerprint = Digest::SHA1.hexdigest("#{fingerprint_builder.join(':')}")
        insert_list << ActiveRecord::Base.quote_value(fingerprint) # fingerprint
        insert_list << ActiveRecord::Base.quote_value(activity.updated_at.to_s(:db)) # activity_at
        insert_list << ActiveRecord::Base.quote_value(Time.zone.now.to_s(:db)) # created_at
        insert_values << "(#{insert_list.join(',')})"
      end

      if(insert_values.size > 0)
        insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
        INSERT IGNORE INTO #{self.table_name}
        (person_id,app_id,app_label,app_source_type,
         activity_code,activity_label,
         app_item_id,source_id,source_model,source_table,
         fingerprint,activity_at,created_at)
        VALUES #{insert_values.join(',')};
        END_SQL
        self.connection.execute(insert_sql)
      end
    end
  end

  def self.learn_versions_activity_import
    # learn edit activity
    database_name = LearnVersion.connection.current_database
    LearnVersion.includes(:learner).where("item_type = 'Event'").find_in_batches do |group|
      insert_values = []
      group.each do |revision|
        next if !(learner = revision.learner)
        next if learner.darmok_id.blank?
        # the core app item is the event
        app_item_id = revision.item_id
        source_id = revision.id
        insert_list = []
        insert_list << learner.darmok_id # person_id
        insert_list << APP_LEARN # app_id
        insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_LEARN])  # app_label
        insert_list << APP_LEARN_VERSIONS # app_source_type
        insert_list << ACTIVITY_EDIT # activity_code
        insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[ACTIVITY_EDIT]) # activity_label
        insert_list << app_item_id # app_item_id
        insert_list << source_id # source_id
        insert_list << ActiveRecord::Base.quote_value('LearnVersion') # source_model
        insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{LearnVersion.table_name}") # source_table
        fingerprint_builder = []
        fingerprint_builder << learner.darmok_id
        fingerprint_builder << APP_LEARN
        fingerprint_builder << ACTIVITY_EDIT
        fingerprint_builder << source_id
        fingerprint_builder << 'LearnVersion'
        fingerprint_builder << revision.created_at.to_s
        fingerprint = Digest::SHA1.hexdigest("#{fingerprint_builder.join(':')}")
        insert_list << ActiveRecord::Base.quote_value(fingerprint) # fingerprint
        insert_list << ActiveRecord::Base.quote_value(revision.created_at.to_s(:db)) # activity_at
        insert_list << ActiveRecord::Base.quote_value(Time.zone.now.to_s(:db)) # created_at
        insert_values << "(#{insert_list.join(',')})"
      end

      if(insert_values.size > 0)
        insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
        INSERT IGNORE INTO #{self.table_name}
        (person_id,app_id,app_label,app_source_type,
         activity_code,activity_label,
         app_item_id,source_id,source_model,source_table,
         fingerprint,activity_at,created_at)
        VALUES #{insert_values.join(',')};
        END_SQL
        self.connection.execute(insert_sql)
      end
    end
  end

  def self.create_workflow_activity_to_activity_code(cwe_activity)
    if(CreateWorkflowEvent::REVIEWED_EVENTS.include?(cwe_activity))
      ACTIVITY_REVIEW
    elsif cwe_activity == CreateWorkflowEvent::PUBLISHED
      ACTIVITY_PUBLISH
    else
      ACTIVITY_WORKFLOW
    end
  end

  def self.create_revisions_activity_import
    database_name = CreateRevision.connection.current_database
    # revisions
    if(get_since = self.where(source_model: 'CreateRevision').maximum(:activity_at))
      get_since_timestamp = get_since.to_i
    else
      get_since_timestamp = CreateRevision.minimum(:timestamp)
    end
    CreateRevision.where("timestamp >= ?",get_since_timestamp).find_in_batches do |group|
      insert_values = []
      group.each do |revision|
        # the core app item is the node
        app_item_id = revision.nid
        source_id = revision.vid
        insert_list = []
        insert_list << revision.uid # person_id
        insert_list << APP_CREATE # app_id
        insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_CREATE])  # app_label
        insert_list << APP_CREATE_REVISIONS # app_source_type
        insert_list << ACTIVITY_EDIT # activity_code
        insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[ACTIVITY_EDIT]) # activity_label
        insert_list << app_item_id # app_item_id
        insert_list << source_id # source_id
        insert_list << ActiveRecord::Base.quote_value('CreateRevision') # source_model
        insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{CreateRevision.table_name}") # source_table
        fingerprint_builder = []
        fingerprint_builder << revision.uid
        fingerprint_builder << APP_CREATE
        fingerprint_builder << ACTIVITY_EDIT
        fingerprint_builder << source_id
        fingerprint_builder << 'CreateRevision'
        fingerprint_builder << revision.created_at.to_s
        fingerprint = Digest::SHA1.hexdigest("#{fingerprint_builder.join(':')}")
        insert_list << ActiveRecord::Base.quote_value(fingerprint) # fingerprint
        insert_list << ActiveRecord::Base.quote_value(revision.created_at.to_s(:db)) # activity_at
        insert_list << ActiveRecord::Base.quote_value(Time.zone.now.to_s(:db)) # created_at
        insert_values << "(#{insert_list.join(',')})"
      end

      if(insert_values.size > 0)
        insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
        INSERT IGNORE INTO #{self.table_name}
        (person_id,app_id,app_label,app_source_type,
         activity_code,activity_label,
         app_item_id,source_id,source_model,source_table,
         fingerprint,activity_at,created_at)
        VALUES #{insert_values.join(',')};
        END_SQL
        self.connection.execute(insert_sql)
      end
    end
  end

  def self.create_workflow_events_activity_import
    database_name = CreateWorkflowEvent.connection.current_database
    # workflow events
    if(get_since = self.where(source_model: 'CreateWorkflowEvent').maximum(:activity_at))
      get_since_timestamp = get_since.to_i
    else
      get_since_timestamp = CreateWorkflowEvent.minimum(:created)
    end
    CreateWorkflowEvent.where("created >= ?",get_since_timestamp).find_in_batches do |group|
      insert_values = []
      group.each do |cwe|
        # the core app item is the node
        app_item_id = cwe.node_id
        source_id = cwe.weid
        insert_list = []
        insert_list << cwe.user_id # person_id
        insert_list << APP_CREATE # app_id
        insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_CREATE])  # app_label
        insert_list << APP_CREATE_WORKFLOW_EVENTS # app_source_type
        activity_code = self.create_workflow_activity_to_activity_code(cwe.event_id)
        insert_list << activity_code # activity_code
        insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[activity_code]) # activity_label
        insert_list << app_item_id # app_item_id
        insert_list << source_id # source_id
        insert_list << ActiveRecord::Base.quote_value('CreateWorkflowEvent') # source_model
        insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{CreateWorkflowEvent.table_name}") # source_table
        fingerprint_builder = []
        fingerprint_builder << cwe.user_id
        fingerprint_builder << APP_CREATE
        fingerprint_builder << activity_code
        fingerprint_builder << source_id
        fingerprint_builder << 'CreateWorkflowEvent'
        fingerprint_builder << cwe.created_at.to_s
        fingerprint = Digest::SHA1.hexdigest("#{fingerprint_builder.join(':')}")
        insert_list << ActiveRecord::Base.quote_value(fingerprint) # fingerprint
        insert_list << ActiveRecord::Base.quote_value(cwe.created_at.to_s(:db)) # activity_at
        insert_list << ActiveRecord::Base.quote_value(Time.zone.now.to_s(:db)) # created_at
        insert_values << "(#{insert_list.join(',')})"
      end

      if(insert_values.size > 0)
        insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
        INSERT IGNORE INTO #{self.table_name}
        (person_id,app_id,app_label,app_source_type,
         activity_code,activity_label,
         app_item_id,source_id,source_model,source_table,
         fingerprint,activity_at,created_at)
        VALUES #{insert_values.join(',')};
        END_SQL
        self.connection.execute(insert_sql)
      end
    end
  end

  def self.create_comments_activity_import
    # comments
    database_name = CreateComment.connection.current_database
    if(get_since = self.where(source_model: 'CreateComment').maximum(:activity_at))
      get_since_timestamp = get_since.to_i
    else
      get_since_timestamp = CreateComment.minimum(:created)
    end
    CreateComment.where("created >= ?",get_since_timestamp).find_in_batches do |group|
      insert_values = []
      group.each do |comment|
        # the core app item is the node
        app_item_id = comment.nid
        source_id = comment.cid
        insert_list = []
        insert_list << comment.uid # person_id
        insert_list << APP_CREATE # app_id
        insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_CREATE])  # app_label
        insert_list << APP_CREATE_COMMENTS # app_source_type
        insert_list << ACTIVITY_COMMENT # activity_code
        insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[ACTIVITY_COMMENT]) # activity_label
        insert_list << app_item_id # app_item_id
        insert_list << source_id # source_id
        insert_list << ActiveRecord::Base.quote_value('CreateComment') # source_model
        insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{CreateComment.table_name}") # source_table
        fingerprint_builder = []
        fingerprint_builder << comment.uid
        fingerprint_builder << APP_CREATE
        fingerprint_builder << ACTIVITY_COMMENT
        fingerprint_builder << source_id
        fingerprint_builder << 'CreateComment'
        fingerprint_builder << comment.created_at.to_s
        fingerprint = Digest::SHA1.hexdigest("#{fingerprint_builder.join(':')}")
        insert_list << ActiveRecord::Base.quote_value(fingerprint) # fingerprint
        insert_list << ActiveRecord::Base.quote_value(comment.created_at.to_s(:db)) # activity_at
        insert_list << ActiveRecord::Base.quote_value(Time.zone.now.to_s(:db)) # created_at
        insert_values << "(#{insert_list.join(',')})"
      end

      if(insert_values.size > 0)
        insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
        INSERT IGNORE INTO #{self.table_name}
        (person_id,app_id,app_label,app_source_type,
         activity_code,activity_label,
         app_item_id,source_id,source_model,source_table,
         fingerprint,activity_at,created_at)
        VALUES #{insert_values.join(',')};
        END_SQL
        self.connection.execute(insert_sql)
      end
    end
  end

  def self.ask_activity_to_activity_code(ask_activity)
    if(ask_activity == AskQuestionEvent::RESOLVED)
      ACTIVITY_ANSWER
    elsif(AskQuestionEvent::GENERAL_HANDLING_EVENTS.include?(ask_activity))
      ACTIVITY_HANDLED
    elsif(ask_activity == AskQuestionEvent::INTERNAL_COMMENT)
      ACTIVITY_COMMENT
    elsif([AskQuestionEvent::EDIT_QUESTION,AskQuestionEvent::EXPERT_EDIT_QUESTION,AskQuestionEvent::EXPERT_EDIT_RESPONSE].include?(ask_activity))
      ACTIVITY_EDIT
    else
      ACTIVITY_OTHER
    end
  end

  def self.ask_questionevent_activity_import
    database_name = AskQuestionEvent.connection.current_database
    # revisions
    if(!get_since = self.where(source_model: 'AskQuestionEvent').maximum(:activity_at))
      get_since = AskQuestionEvent.minimum(:created_at)
    end
    AskQuestionEvent.includes(:initiator).where("created_at >= ?",get_since).find_in_batches do |group|
      insert_values = []
      group.each do |question_event|
        next if !(ask_user = question_event.initiator)
        next if ask_user.darmok_id.blank?
        # the core app item is the question
        app_item_id = question_event.question_id
        source_id = question_event.id
        insert_list = []
        insert_list << ask_user.darmok_id # person_id
        insert_list << APP_ASK # app_id
        insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_ASK])  # app_label
        insert_list << APP_ASK_QUESTIONEVENTS # app_source_type
        activity_code = self.ask_activity_to_activity_code(question_event.event_state)
        insert_list << activity_code # activity_code
        insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[activity_code]) # activity_label
        insert_list << app_item_id # app_item_id
        insert_list << source_id # source_id
        insert_list << ActiveRecord::Base.quote_value('AskQuestionEvent') # source_model
        insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{AskQuestionEvent.table_name}") # source_table
        fingerprint_builder = []
        fingerprint_builder << ask_user.darmok_id
        fingerprint_builder << APP_ASK
        fingerprint_builder << activity_code
        fingerprint_builder << source_id
        fingerprint_builder << 'AskQuestionEvent'
        fingerprint_builder << question_event.created_at.to_s
        fingerprint = Digest::SHA1.hexdigest("#{fingerprint_builder.join(':')}")
        insert_list << ActiveRecord::Base.quote_value(fingerprint) # fingerprint
        insert_list << ActiveRecord::Base.quote_value(question_event.created_at.to_s(:db)) # activity_at
        insert_list << ActiveRecord::Base.quote_value(Time.zone.now.to_s(:db)) # created_at
        insert_values << "(#{insert_list.join(',')})"
      end

      if(insert_values.size > 0)
        insert_sql = <<-END_SQL.gsub(/\s+/, " ").strip
        INSERT IGNORE INTO #{self.table_name}
        (person_id,app_id,app_label,app_source_type,
         activity_code,activity_label,
         app_item_id,source_id,source_model,source_table,
         fingerprint,activity_at,created_at)
        VALUES #{insert_values.join(',')};
        END_SQL
        self.connection.execute(insert_sql)
      end
    end
  end

  # todo? merge in People Activity?

  def self.periodic_activity_by_person_id(options = {})
    returndata = {}
    months = options[:months]
    end_date = options[:end_date]
    start_date = end_date - months.months
    persons = self.where("DATE(created_at) >= ?",start_date).where('person_id > 1').pluck('person_id').uniq
    returndata['months'] = months
    returndata['start_date'] = start_date
    returndata['end_date'] = end_date
    returndata['people_count'] = persons.size
    returndata['people'] = {}
    persons.each do |person_id|
      returndata['people'][person_id] ||= {}
      base_scope = self.where("DATE(created_at) >= ?",start_date).where('person_id = ?',person_id)
      returndata['people'][person_id]['dates'] = base_scope.pluck('DATE(created_at)').uniq
      returndata['people'][person_id]['days'] = returndata['people'][person_id]['dates'].size
      returndata['people'][person_id]['items'] = base_scope.count('DISTINCT(item_fingerprint)')
      returndata['people'][person_id]['actions'] = base_scope.count('id')
    end
    returndata
  end

end
