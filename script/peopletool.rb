#!/usr/bin/env ruby
# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file
require 'rubygems'
require 'thor'

class PeopleTool < Thor
  include Thor::Actions
  class_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"


  # these are not the tasks that you seek
  no_tasks do

    # load rails based on environment
    def load_rails(environment)
      if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
        ENV["RAILS_ENV"] = environment
      end
      require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
    end

    # this utility method is named the same as the Person class method
    # Do not be led astray by any confusion there.  Embrace the consistency
    def find_by_email_or_idstring_or_id(email_idstring_id)
      if(!(person = Person.find_by_email_or_idstring_or_id(email_idstring_id,false)))
        say("Unable to find anyone with the email address or idstring or id number: #{email_idstring_id}", :red)
        exit(1)
      end
      return person
    end



  end

  desc "add_email_alias <idstring_or_idnumber> <email_alias>", "Add an email alias <email_alias> to a people account (idstring or id#) e."
  method_option :nomirror, :default => false, :desc => "Do not add alias to mirror mailbox (systemsmirror)", :required => true
  def add_email_alias(email_idstring_id, email_alias)
    load_rails(options[:environment])
    person = find_by_email_or_idstring_or_id(email_idstring_id)
    add_mirror = !options[:nomirror]
    if(options[:nomirror] and EmailAlias.mirror_alias_exists?(email_alias))
      # inform mirror exists anyway
      say("Note: #{email_alias}@extension.org is mirrored already",:yellow)
    end
    if(person.has_email_alias?(email_alias))
      say("Note: #{email_alias}@extension.org is already delivering to #{person.fullname} (#{person.idstring})",:yellow)
    elsif(ea = person.add_email_alias(email_alias, add_mirror: add_mirror))
      mirror_op = add_mirror ? 'with mirroring' : 'without mirroring'
      say("Added #{ea.mail_alias_address} to #{person.fullname} (#{person.idstring}) #{mirror_op}", :green)
    else
      say("Unable to add #{ea.mail_alias_address} to #{person.fullname} (#{person.idstring})", :yellow)
    end
  end

end

PeopleTool.start(ARGV)
