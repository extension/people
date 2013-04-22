# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class NodeActivity < ActiveRecord::Base
  extend YearWeek
  belongs_to :node
  belongs_to :contributor

  DRAFT = 1
  READY_FOR_REVIEW = 2
  REVIEWED = 3
  READY_FOR_PUBLISH = 4
  PUBLISHED = 5
  UNPUBLISHED = 6
  INACTIVATED = 7
  ACTIVATED = 8
  READY_FOR_COPYEDIT = 9

  EDIT = 101
  COMMENT = 102

  REVIEWED_EVENTS = [READY_FOR_REVIEW,REVIEWED,READY_FOR_PUBLISH,READY_FOR_COPYEDIT]

  EVENT_STRINGS = {
    DRAFT => 'moved to draft',
    READY_FOR_REVIEW => 'marked ready for review',
    REVIEWED => 'reviewed',
    READY_FOR_PUBLISH => 'marked ready for publishing',
    PUBLISHED => 'published',
    UNPUBLISHED => 'unpublished',
    INACTIVATED => 'marked inactive',
    ACTIVATED => 'marked as active',
    READY_FOR_COPYEDIT => 'marked ready for copy editing',
    EDIT => 'edited',
    COMMENT => 'added comment'
  }

  scope :created_since, lambda {|date| where("#{self.table_name}.created_at >= ?",date)}

  # event groups
  ALL_ACTIVITY = 'all'
  EDIT_ACTIVITY = 'edit'
  COMMENT_ACTIVITY = 'comment'
  REVIEW_ACTIVITY = 'review'
  PUBLISH_ACTIVITY = 'publish'
  OTHER_ACTIVITY = 'other'

  # used as a sanitycheck list
  ACTIVITIES = ['all','edit','comment','review','publish','other']


  def self.event_to_s(event)
    if(EVENT_STRINGS[event])
      EVENT_STRINGS[event]
    else
      'unknown'
    end
  end

  def event_to_s
    self.class.event_to_s(self.event)
  end

  def self.earliest_year_week
    if(@yearweek.blank?)
      earliest_date = self.minimum(:created_at).to_date
      @yearweek = [earliest_date.cwyear,earliest_date.cweek]
    end
    @yearweek
  end

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")

    # revisions
    CreateRevision.find_in_batches do |group|
      insert_values = []
      group.each do |revision|
        insert_list = []
        insert_list << revision.nid
        insert_list << revision.uid
        insert_list << revision.vid
        insert_list << EDIT
        insert_list << ActiveRecord::Base.quote_value(EDIT_ACTIVITY)
        insert_list << ActiveRecord::Base.quote_value(revision.log)
        insert_list << ActiveRecord::Base.quote_value(revision.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (node_id,contributor_id,node_revision_id,event,activity,log,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end

    # workflow events
    CreateWorkflowEvent.find_in_batches do |group|
      insert_values = []
      group.each do |cwe|
        insert_list = []
        insert_list << cwe.node_id
        insert_list << cwe.user_id
        insert_list << cwe.revision_id
        insert_list << cwe.event_id
        if(REVIEWED_EVENTS.include?(cwe.event_id))
          insert_list << ActiveRecord::Base.quote_value(REVIEW_ACTIVITY)
        elsif cwe.event_id == PUBLISHED
          insert_list << ActiveRecord::Base.quote_value(PUBLISH_ACTIVITY)
        else
          insert_list << ActiveRecord::Base.quote_value(OTHER_ACTIVITY)
        end
        insert_list << ActiveRecord::Base.quote_value(cwe.description)
        insert_list << ActiveRecord::Base.quote_value(cwe.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (node_id,contributor_id,node_revision_id,event,activity,log,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end

    # comments
    CreateComment.find_in_batches do |group|
      insert_values = []
      group.each do |comment|
        insert_list = []
        insert_list << comment.nid
        insert_list << comment.uid
        insert_list << COMMENT
        insert_list << ActiveRecord::Base.quote_value(COMMENT_ACTIVITY)
        insert_list << ActiveRecord::Base.quote_value(comment.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (node_id,contributor_id,event,activity,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
    true
  end

  def is_reviewed_event?
    event_group == REVIEW_EVENT
  end

  def self.stats(activity)
    returnstats = {}
    if(!(ACTIVITY_SCOPES.include?(activity)))
      return returnstats
    end
    with_scope do
      returnstats['contributions'] = self.send(activity).count
      returnstats['contributors'] = self.send(activity).count(:contributor_id,:distinct => true)
      returnstats['items'] = self.send(activity).count(:node_id,:distinct => true)
    end
    returnstats
  end

  def self.stats_by_yearweek(activity)
    returnstats = {}
    if(!(ACTIVITY_SCOPES.include?(activity)))
      return returnstats
    end
    with_scope do
      # get the byweek groupings
      by_yearweek_stats = self.group("YEARWEEK(node_activities.created_at,3)").stats(activity)
      self.eligible_year_weeks.each do |year,week|
        yearweek = self.yearweek(year,week)
        returnstats[yearweek] = {}
        ['contributions','items','contributors'].each do |column_value|
          if(by_yearweek_stats[column_value][yearweek])
            returnstats[yearweek][column_value] = by_yearweek_stats[column_value][yearweek]
          else
            returnstats[yearweek][column_value] = 0
          end
        end
      end
    end
    returnstats
  end


  def self.eligible_year_weeks
    latest_date = Analytic.latest_date
    with_scope do
      # scoped start date
      earliest_created_at = self.minimum(:created_at)
      if(!earliest_created_at.nil?)
        start_date = earliest_created_at.to_date
        self.year_weeks_between_dates(start_date,latest_date)
      else
        []
      end
    end
  end

  def self.contributions_display(contributions)
    list = contributions.split(',')
    list.uniq.map{|contribution| self.event_to_s(contribution.to_i)}.join(', ')
  end



end
