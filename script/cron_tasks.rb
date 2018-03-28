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

    def cleanup_signups
      selist = SignupEmail.cleanup_signups
      idlist = selist.map{|a| "##{a.id}"}
      puts "Removed signup emails: #{idlist.join(', ')}"
    end

    def cleanup_referer_tracks
      rtlist = RefererTrack.cleanup_unused_tracks
      idlist = rtlist.map{|a| "##{a.id}"}
      puts "Removed referer tracks: #{idlist.join(', ')}"
    end

    def cleanup_pending_accounts
      accounts = Person.cleanup_pending_accounts
      idlist = accounts.map{|a| "##{a.id}"}
      puts "Retired pending accounts: #{idlist.join(', ')}"
    end

    def create_account_reminders
      Person.reminder_pool.each do |person|
        puts "Sending account reminder to #{person.email}"
        person.send_account_reminder
      end
    end

    def cleanup_invitations
      invitations = Invitation.remove_expired_invitations
      email_list = invitations.map{|i| "#{i.email}"}
      puts "Cleaning up invitations: #{email_list.join(', ')}"
    end

    def expire_passwords
      accounts = Person.expire_retired_account_passwords
      idlist = accounts.map{|a| "##{a.id}"}
      puts "Cleared passwords for the following retired accounts: #{idlist.join(', ')}"
    end

    def import_activity
      puts "Importing activity..."
      results = ActivityImport.go_and_import('all')
      results.each do |item,result|
        puts "  #{item} #{result ? 'success' : 'failed'}"
      end
    end

    def queue_members_update_for_all_groups
      puts "Queuing members updates for all groups... "
      groups = GoogleGroup.queue_members_update_for_all_groups
      puts "queued update for #{groups.size} groups"
    end
  end

  desc "daily", "All daily cron tasks"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def daily
    load_rails(options[:environment])
    cleanup_signups
    cleanup_referer_tracks
    cleanup_pending_accounts
    cleanup_invitations
    expire_passwords
    create_account_reminders
    queue_members_update_for_all_groups
    #import_activity
  end

  desc "hourly", "All hourly cron tasks"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  def hourly
    load_rails(options[:environment])
    #no-op
  end

end

CronTasks.start
