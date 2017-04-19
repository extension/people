# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AppActivity < ActiveRecord::Base
  serialize :additionaldata
  extend DateTools

  attr_accessible :trackable, :trackable_id, :trackable_type
  attr_accessible :app_id, :activity_code
  attr_accessible :section_id, :section_label # relevant to publish site
  attr_accessible :source_model
  attr_accessible :year, :month, :quarter
  attr_accessible :item_count, :activity_count, :person_count, :pool_count
  attr_accessible :additionaldata



  # tracked applications
  APP_ARTICLES  = 100
  APP_ASK       = 200
  APP_PUBLISH   = 300
  APP_CREATE    = 400
  APP_HOMEPAGE  = 500
  APP_LEARN     = 600
  APP_MILFAM    = 700
  APP_PEOPLE    = 800

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

  # activity codes
  APP_LEARN_PRESENTED_EVENTS = 601



  ACTIVITY_LABELS = {
    APP_LEARN_PRESENTED_EVENTS => 'presented learn events'
  }

  def self.find_by_unique_key(attributes)
    self.where(trackable_id: attributes[:trackable_id]) \
        .where(trackable_type: attributes[:trackable_type]) \
        .where(year: attributes[:year]) \
        .where(quarter: attributes[:quarter]) \
        .where(month: attributes[:month]) \
        .where(activity_code: attributes[:activity_code]).first
  end


  def self.loop_presented_events_by_extensionid(start_date,end_date)

    years = self.years_between_dates(start_date,end_date)
    year_quarters = self.year_quarters_between_dates(start_date,end_date)
    year_months = self.year_months_between_dates(start_date,end_date)

    # years
    years.each do |year|
      get_presented_events_by_extensionid(year: year, month: 0, quarter: 0)
    end

    # year+quarters
    year_quarters.each do |year,quarter|
      get_presented_events_by_extensionid(year: year, month: 0, quarter: quarter)
    end

    # year+months
    year_months.each do |year,month|
      get_presented_events_by_extensionid(year: year, month: month, quarter: 0)
    end

  end

  def self.get_presented_events_by_extensionid(options = {})
    base_record_params = {
      :app_id => APP_LEARN,
      :activity_code => APP_LEARN_PRESENTED_EVENTS,
      :source_model => 'LearnPresenterConnection',
      :trackable_type => 'Person',
      :person_count => 1,
      :pool_count => 1
    }
    record_params = base_record_params.merge(options)
    presenters_and_events = LearnPresenterConnection.get_events_by_extensionid(options)
    presenters_and_events.each do |presenter_id,event_list|
      count_params = {
        :trackable_id => presenter_id,
        :item_count => event_list.uniq.size,
        :activity_count => event_list.uniq.size,
        :additionaldata => event_list
      }
      record_params.merge!(count_params)
      begin
        self.create(record_params)
      rescue ActiveRecord::RecordNotUnique => e
        record = self.find_by_unique_key(record_params)
        record.update_attributes(count_params)
      end
    end
  end








end
