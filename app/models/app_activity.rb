# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AppActivity < ActiveRecord::Base
  serialize :additionaldata

  # t.integer  "person_id",        :default => 0
  # t.integer  "app_id",           :default => 0
  # t.string   "app_label",        :limit => 25
  # t.integer  "section_id",       :default => 1
  # t.string   "section_label",    :limit => 25
  # t.integer  "activity_code",    :default => 0
  # t.string   "activity_label",   :limit => 25
  # t.integer  "item_id",          :default => 0
  # t.integer  "item_revision_id", :default => 0
  # t.integer  "source_id", :default => 0
  # t.string   "source_model"
  # t.string   "ip_address",       :limit => 45
  # t.string   "fingerprint",      :limit => 64
  # t.text     "additionaldata"
  # t.datetime "activity_at"
  # t.datetime "created_at"

  # tracked applications
  APP_ARTICLES  = 1
  APP_ASK       = 2
  APP_BLOGS     = 3
  APP_CREATE    = 4
  APP_HOMEPAGE  = 5
  APP_LEARN     = 6
  APP_MILFAM    = 7
  APP_PEOPLE    = 8

  # tracked application labels
  APP_LABELS = {
    APP_ARTICLES => 'articles',
    APP_ASK => 'ask',
    APP_BLOGS => 'blogs',
    APP_CREATE => 'create',
    APP_HOMEPAGE => 'homepage',
    APP_LEARN => 'learn',
    APP_MILFAM => 'milfam',
    APP_PEOPLE => 'people'
  }

  # activities
  ACTIVITY_EDIT = 1
  ACTIVITY_COMMENT = 2

  ACTIVITY_LABELS = {
    ACTIVITY_EDIT => 'edit',
    ACTIVITY_COMMENT => 'comment'
  }

  def self.blogs_update
    BlogsBlog.order(:blog_id).each do |blog|
      blog_id = blog.blog_id
      blog_name = blog.path.gsub('/','')
      blog_name = 'root' if(blog_name.blank?)

      # edits
      postcount = BlogsBlogpost.repoint(blog_id)
      database_name = BlogsBlogpost.connection.current_database
      next if(postcount.nil? or postcount == 0)
      next if(BlogsBlogpost.activity_entries.count == 0)
      insert_values = []
      post_scope = BlogsBlogpost.includes(:blogs_user => :blogs_openid).activity_entries
      # if(!blogs_updated_at.nil?)
      #   post_scope = post_scope.where("post_date > ?",blogs_updated_at)
      # end
      post_scope.each do |posting|
        next if !(user = posting.blogs_user)
        next if !(openid = user.blogs_openid)
        insert_list = []
        insert_list << posting.post_author # person_id
        insert_list << APP_BLOGS # app_id
        insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_BLOGS])  # app_label
        insert_list << blog_id # section_id
        insert_list << ActiveRecord::Base.quote_value(blog_name)  # section_label
        insert_list << ACTIVITY_EDIT # activity_code
        insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[ACTIVITY_EDIT]) # activity_label
        item_id = (posting.post_parent != 0 ? posting.post_parent : posting.ID)
        insert_list << item_id # item_id
        insert_list << posting.ID # item_revision_id
        item_fingerprint_builder = []
        item_fingerprint_builder << APP_BLOGS
        item_fingerprint_builder << blog_id
        item_fingerprint_builder << 'BlogsBlogpost'
        item_fingerprint_builder << item_id
        item_fingerprint = Digest::SHA1.hexdigest("#{item_fingerprint_builder.join(':')}")
        insert_list << ActiveRecord::Base.quote_value(item_fingerprint) # item_fingerprint
        insert_list << posting.ID # source_id
        insert_list << ActiveRecord::Base.quote_value('BlogsBlogpost') # source_model
        insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{BlogsBlogpost.table_name}") # source_table
        # fingerprint = person_id:app_id:section_id:activity_code:item_fingerprint:activity_at
        fingerprint_builder = []
        fingerprint_builder << posting.post_author
        fingerprint_builder << APP_BLOGS
        fingerprint_builder << blog_id
        fingerprint_builder << ACTIVITY_EDIT
        fingerprint_builder << item_fingerprint
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
        (person_id,app_id,app_label,section_id,section_label,
         activity_code,activity_label,item_id,item_revision_id,
         item_fingerprint,source_id,source_model,source_table,
         fingerprint,activity_at,created_at)
        VALUES #{insert_values.join(',')};
        END_SQL
        self.connection.execute(insert_sql)
      end


      commentcount = BlogsBlogcomment.repoint(blog_id)
      database_name = BlogsBlogcomment.connection.current_database
      next if(commentcount.nil? or commentcount == 0)
      next if (BlogsBlogcomment.user_activities.count == 0)
      insert_values = []
      BlogsBlogcomment.includes(:blogs_user => :blogs_openid).user_activities.each do |comment|
        next if !(user = comment.blogs_user)
        next if !(openid = user.blogs_openid)
        insert_list = []
        insert_list << comment.user_id # person_id
        insert_list << APP_BLOGS # app_id
        insert_list << ActiveRecord::Base.quote_value(APP_LABELS[APP_BLOGS])  # app_label
        insert_list << blog_id # section_id
        insert_list << ActiveRecord::Base.quote_value(blog_name)  # section_label
        insert_list << ACTIVITY_COMMENT # activity_code
        insert_list <<  ActiveRecord::Base.quote_value(ACTIVITY_LABELS[ACTIVITY_COMMENT]) # activity_label
        item_id = comment.comment_ID
        insert_list << item_id # item_id
        insert_list << 0 # item_revision_id
        item_fingerprint_builder = []
        item_fingerprint_builder << APP_BLOGS
        item_fingerprint_builder << blog_id
        item_fingerprint_builder << 'BlogsBlogcomment'
        item_fingerprint_builder << item_id
        item_fingerprint = Digest::SHA1.hexdigest("#{item_fingerprint_builder.join(':')}")
        insert_list << ActiveRecord::Base.quote_value(item_fingerprint) # item_fingerprint
        insert_list << comment.comment_ID # source_id
        insert_list << ActiveRecord::Base.quote_value('BlogsBlogcomment') # source_model
        insert_list << ActiveRecord::Base.quote_value("#{database_name}.#{BlogsBlogcomment.table_name}") # source_table
        # fingerprint = person_id:app_id:section_id:activity_code:item_fingerprint:activity_at
        fingerprint_builder = []
        fingerprint_builder << comment.user_id
        fingerprint_builder << APP_BLOGS
        fingerprint_builder << blog_id
        fingerprint_builder << ACTIVITY_COMMENT
        fingerprint_builder << item_fingerprint
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
        (person_id,app_id,app_label,section_id,section_label,
         activity_code,activity_label,item_id,item_revision_id,
         item_fingerprint,source_id,source_model,source_table,
         fingerprint,activity_at,created_at)
        VALUES #{insert_values.join(',')};
        END_SQL
        self.connection.execute(insert_sql)
      end
    end # blogs list
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
