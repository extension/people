# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file
require 'rubygems'
require 'thor'

class CronTasks < Thor
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

    def cleanup_signup_accounts
      accounts = Person.cleanup_signup_accounts
      idlist = accounts.map{|a| "##{a.id}"}
      puts "Removed accounts: #{idlist.join(', ')}"
    end

    def cleanup_pending_accounts
      accounts = Person.cleanup_pending_accounts
      idlist = accounts.map{|a| "##{a.id}"}
      puts "Retired pending accounts: #{idlist.join(', ')}"
    end

    # limit = 13 assumes hourly
    def create_account_reminders(limit = 13)
      Person.reminder_pool.limit(limit).each do |person|
        puts "Sending account reminder to #{person.email}"
        person.send_account_reminder
      end
    end

  end

  desc "daily", "All daily cron tasks"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def daily
    load_rails(options[:environment])
    cleanup_signup_accounts
    cleanup_pending_accounts
  end

  desc "hourly", "All hourly cron tasks"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def hourly
    load_rails(options[:environment])
    create_account_reminders(50)
  end 

end

CronTasks.start