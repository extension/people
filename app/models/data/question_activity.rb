# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class QuestionActivity < ActiveRecord::Base
  extend YearMonth

  belongs_to :question
  belongs_to :person

## constants
  ASSIGNED_TO = 1
  RESOLVED = 2
  REACTIVATE = 5
  REJECTED = 6
  NO_ANSWER = 7
  TAG_CHANGE = 8
  WORKING_ON = 9
  EDIT_QUESTION = 10
  PUBLIC_RESPONSE = 11
  REOPEN = 12
  CLOSED = 13
  INTERNAL_COMMENT = 14
  ASSIGNED_TO_GROUP = 15
  CHANGED_GROUP = 16
  CHANGED_LOCATION = 17

  scope :resolved, where(activity: RESOLVED)

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    AaeQuestionEvent.includes(:initiator).find_in_batches(:batch_size => 100) do |question_event_group|
      insert_values = []
      question_event_group.each do |qe|
        insert_list = []
        contributor = qe.initiator
        next if(contributor.nil? or contributor.id == 1 or !contributor.has_exid?)
        insert_list << qe.id
        insert_list << contributor.darmok_id
        insert_list << qe.question_id
        insert_list << qe.event_state
        insert_list << (AaeQuestionEvent::EVENT_TO_TEXT_MAPPING[qe.event_state].nil? ? 'NULL' : ActiveRecord::Base.quote_value(AaeQuestionEvent::EVENT_TO_TEXT_MAPPING[qe.event_state]))       
        insert_list << ActiveRecord::Base.quote_value(qe.created_at.utc.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end # question_group
      columns = self.column_names
      insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end # all questions
  end

  def self.experts_for_year_month(year_month)
    with_scope do
      self.where("DATE_FORMAT(activity_at,'%Y-%m') = ?",year_month_string(year_month)).pluck('person_id').uniq
    end
  end

  def self.yearly_expert_growth(year)
    year_month_counts = {}
    with_scope do
      (1..12).each do |month|
        yms = year_month_string([year,month])
        end_of_month = Date.strptime(yms,'%Y-%m').end_of_month
        unique_count = self.where('YEAR(activity_at) = ?',year).where('DATE(activity_at) <= ?',end_of_month.to_s(:db)).count('DISTINCT(person_id)')
        year_month_counts[yms] = unique_count
      end
    end
    year_month_counts
  end


  def self.monthly_changeover_for_year_month(year_month)
    returnvalues = {new: 0, returning: 0, lost: 0}
    with_scope do
      experts_this_month = experts_for_year_month(year_month)
      experts_previous_month = experts_for_year_month(previous_year_month(year_month))
      returnvalues[:total] = experts_this_month
      returnvalues[:new] = experts_this_month - experts_previous_month
      returnvalues[:lost] = experts_previous_month - experts_this_month
      returnvalues[:returning] = experts_this_month & experts_previous_month
    end
    returnvalues
  end

  def self.changeover_counts(changeover)
    counts = {}
    [:total,:new,:returning,:lost].each do |metric|
      counts[metric] = changeover[metric].size
    end
    counts
  end

  def self.maximum_data_date 
    self.maximum(:activity_at).to_date
  end  


  def self.periodic_activity_by_person_id(options = {})
    returndata = {}
    months = options[:months]
    end_date = options[:end_date]
    start_date = end_date - months.months
    persons = self.where("DATE(activity_at) >= ?",start_date).where('person_id > 1').pluck('person_id').uniq
    returndata['months'] = months
    returndata['start_date'] = start_date
    returndata['end_date'] = end_date
    returndata['people_count'] = persons.size
    returndata['people'] = {}
    persons.each do |person_id|
      returndata['people'][person_id] ||= {}
      base_scope = self.where("DATE(activity_at) >= ?",start_date).where('person_id = ?',person_id)
      returndata['people'][person_id]['dates'] = base_scope.pluck('DATE(activity_at)').uniq
      returndata['people'][person_id]['days'] = returndata['people'][person_id]['dates'].size
      returndata['people'][person_id]['items'] = base_scope.count('DISTINCT(question_id)')
      returndata['people'][person_id]['actions'] = base_scope.count('id')
    end
    returndata
  end

  def self.increase_group_concat_length
    set_group_concat_size_query = "SET SESSION group_concat_max_len = #{Settings.group_concat_max_len};"
    self.connection.execute(set_group_concat_size_query)
  end

  def self.earliest_activity_at
    with_scope do
      ea = self.minimum(:activity_at)
      (ea < EpochDate::WWW_LAUNCH) ? EpochDate::WWW_LAUNCH : ea
    end
  end

  def self.latest_activity_at
    with_scope do
      self.maximum(:activity_at)
    end
  end

  def self.stats_by_yearweek(cache_options = {})
    if(!cache_options[:nocache])
      cache_key = self.get_cache_key(__method__,{scope_sql: current_scope ? current_scope.to_sql : ''})
      Rails.cache.fetch(cache_key,cache_options) do
        with_scope do
          _stats_by_yearweek(cache_options)
        end
      end
    else
      with_scope do
        _stats_by_yearweek(cache_options)
      end
    end
  end

  def self._stats_by_yearweek(cache_options = {})
    metric = 'experts'
    stats = YearWeekStats.new
    # increase_group_concat_length
    with_scope do
      ea = self.earliest_activity_at
      if(ea.blank?)
        return stats
      end
      la = self.latest_activity_at - 1.week

      metric_by_yearweek = self.group(YEARWEEK_ACTIVE).count('DISTINCT(contributor_id)')

      year_weeks = self.year_weeks_between_dates(ea.to_date,la.to_date)
      year_weeks.each do |year,week|
        yw = self.yearweek(year,week)
        stats[yw] = {}
        metric_value = metric_by_yearweek[yw] || 0
        stats[yw][metric] = metric_value

        previous_year_key = self.yearweek(year-1,week)
        (previous_year,previous_week) = self.previous_year_week(year,week)
        previous_week_key = self.yearweek(previous_year,previous_week)

        previous_week = (metric_by_yearweek[previous_week_key]  ? metric_by_yearweek[previous_week_key] : 0)
        stats[yw]["previous_week_#{metric}"] = previous_week
        previous_year = (metric_by_yearweek[previous_year_key]  ? metric_by_yearweek[previous_year_key] : 0)
        stats[yw]["previous_year_#{metric}"] = previous_year

        # pct_change
        if(previous_week == 0)
          stats[yw]["pct_change_week_#{metric}"] = nil
        else
          stats[yw]["pct_change_week_#{metric}"] = (metric_value - previous_week) / previous_week.to_f
        end

        if(previous_year == 0)
          stats[yw]["pct_change_year_#{metric}"] = nil
        else
          stats[yw]["pct_change_year_#{metric}"] = (metric_value - previous_year) / previous_year.to_f
        end
      end
    end
    stats
  end  
  



end
