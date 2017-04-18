# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class LearnEventConnection < ActiveRecord::Base
  # connects to the learn database
  self.establish_connection :learn
  self.table_name='event_connections'

  # connection types
  BOOKMARK = 3
  ATTEND = 4
  WATCH = 5

  belongs_to :event, class_name: 'LearnEvent',foreign_key: 'event_id'
  belongs_to :learner, class_name: 'LearnLearner',foreign_key: 'learner_id'

  scope :event_date_filtered, ->(start_date,end_date) {includes(:event).where('DATE(events.session_start) >= ? AND DATE(events.session_start) <= ?', start_date, end_date) }

  scope :bookmarked, ->{where(connectiontype: BOOKMARK)}
  scope :attended, ->{where(connectiontype: ATTEND)}
  scope :watched, ->{where(connectiontype: WATCH)}

  def self.get_events_by_extensionid(connectiontype,options = {})
    today = Date.today
    if(options[:year])
      year = options[:year]
    else
      year = today.year
    end
    base_scope = self.joins(:learner,:event) \
                     .select("#{self.table_name}.*,#{LearnLearner.table_name}.darmok_id as extension_id") \
                     .where("#{LearnEvent.table_name}.is_deleted = ?",false)
                     .where("#{LearnEvent.table_name}.is_canceled = ?",false)
                     .where("DATE(#{LearnEvent.table_name}.session_start) <= ?",today)
                     .where(connectiontype: connectiontype)
    date_scope = base_scope.where("YEAR(events.session_start) = ?",year)
    if(options[:month] and (1..12).to_a.include?(options[:month]))
      date_scope = date_scope.where("MONTH(events.session_start) = ?",options[:month])
    elsif(options[:quarter] and (1..4).to_a.include?(options[:quarter]))
      date_scope = date_scope.where("QUARTER(events.session_start) = ?",options[:quarter])
    end
    if(options[:limit_to_ids])
      query_scope = date_scope.where("#{LearnLearner.table_name}.darmok_id IN (#{options[:limit_to_ids].join(',')})")
    else
      query_scope = date_scope
    end

    events_by_extensionid = {}
    query_scope.each do |presenter_connection|
      id_value = presenter_connection.extension_id || 0
      if(!events_by_extensionid[id_value].blank?)
        events_by_extensionid[id_value] << presenter_connection.event_id
      else
        events_by_extensionid[id_value] = [presenter_connection.event_id]
      end
    end
    events_by_extensionid
  end

end
