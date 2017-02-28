#!/usr/bin/env ruby
# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file
require 'rubygems'
require 'thor'
require 'csv'

class DataExport < Thor
  include Thor::Actions

  # these are not the tasks that you seek
  no_tasks do

    # load rails based on environment
    def load_rails(environment)
      if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
        ENV["RAILS_ENV"] = environment
      end
      require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
    end

  end

  desc "site_logins", "Logins by site"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :start_date, :aliases => "-s", :desc => "Start Date", :required => true
  method_option :end_date, :aliases => "-e", :desc => "End Date", :required => true
  method_option :output_file, :aliases => "-o", :desc => "Output File", :required => true
  def site_logins
    load_rails(options[:environment])
    output_file = options[:output_file]
    start_date = Date.parse(options[:start_date])
    end_date = Date.parse(options[:end_date])
    say("Writing site logins between #{start_date} and #{end_date} to #{output_file}")
    sites = Site.order(:label).all
    activity_data = {}
    sites.each do |s|
      activity_data[s.id] = Activity.site_logins \
                                    .where("site = '#{s.uri}' or site = '#{s.uri}/'") \
                                    .where('DATE(created_at) >= ?',start_date) \
                                    .where('DATE(created_at) <= ?',end_date) \
                                    .group(:person_id)
                                    .count(:id)
    end

    # get the master id list
    actives = []
    activity_data.each do |site_id,login_counts|
      actives |= login_counts.keys
    end
    actives.sort!

    CSV.open(output_file,'wb') do |csv|
      site_labels = sites.map(&:label)
      headers = ['idstring','first','last','institution']
      headers += site_labels
      csv << headers
      actives.each do |id|
        if(p = Person.where(id: id).first)
          row = []
          row << p.idstring
          row << p.first_name
          row << p.last_name
          row << (p.institution.nil? ? 'n/a' : p.institution.name)
          sites.each do |s|
            if(activity_data[s.id] and activity_data[s.id][p.id])
              row << activity_data[s.id][p.id]
            else
              row << 0
            end
          end
          csv << row
        end
      end
    end
  end
end

DataExport.start
