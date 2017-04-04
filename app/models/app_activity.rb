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
  ACTIVITY_GENERIC = 0
  ACTIVITY_EDIT = 1
  ACTIVITY_COMMENT = 2
  ACTIVITY_BOOKMARK = 3
  ACTIVITY_ATTEND = 4
  ACTIVITY_WATCH = 5
  ACTIVITY_RATING = 6
  ACTIVITY_ANSWER = 7
  ACTIVITY_REVIEW = 8
  ACTIVITY_PUBLISH = 9
  ACTIVITY_WORKFLOW = 10

  ACTIVITY_LABELS = {
    ACTIVITY_GENERIC => 'activity',
    ACTIVITY_EDIT => 'edit',
    ACTIVITY_COMMENT => 'comment',
    ACTIVITY_BOOKMARK => 'bookmark',
    ACTIVITY_ATTEND => 'attend',
    ACTIVITY_WATCH => 'watch',
    ACTIVITY_RATING => 'rating',
    ACTIVITY_ANSWER => 'answer',
    ACTIVITY_REVIEW => 'review',
    ACTIVITY_PUBLISH => 'publish',
    ACTIVITY_WORKFLOW => 'workflow'
  }

  def self.publish_update
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
        insert_list << ActiveRecord::Base.quote_value(blog_name)  # section_label
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
        insert_list << ActiveRecord::Base.quote_value(blog_name)  # section_label
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

  def self.learn_activity_to_activity_code(learn_activity)
    case learn_activity
    when LearnEventActivity::ANSWER
      ACTIVITY_ANSWER
    when LearnEventActivity::RATING
      ACTIVITY_RATING
    when LearnEventActivity::RATING_ON_COMMENT
      ACTIVITY_RATING
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
      ACTIVITY_GENERIC
    end
  end

  def self.learn_update
    self.learn_event_activities_update
    self.learn_versions_update
  end

  def self.learn_event_activities_update
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

  def self.learn_versions_update
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

  def self.create_update
    self.create_revisions_update
    self.create_workflow_events_update
    self.create_comments_update
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

  def self.create_revisions_update
    database_name = CreateRevision.connection.current_database
    # revisions
    CreateRevision.find_in_batches do |group|
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

  def self.create_workflow_events_update
    database_name = CreateWorkflowEvent.connection.current_database
    # workflow events
    CreateWorkflowEvent.find_in_batches do |group|
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

  def self.create_comments_update
    # comments
    database_name = CreateComment.connection.current_database
    CreateComment.find_in_batches do |group|
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
