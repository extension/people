# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file
require 'rubygems'
require 'thor'

class CampusDataMatch < Thor
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

    def match_test(campus_data_row)
      campus_email_address = campus_data_row['email']
      first_name = campus_data_row['firstname']
      last_name = campus_data_row['lastname']

      match_hash = {'match' => 'no'}
      if(p = Person.where(email: campus_email_address).first)
        match_hash =  {'match' => 'yes',
                       'people_id' => p.id,
                       'people_idstring' => p.idstring,
                       'people_email' => p.email,
                       'people_name' => p.fullname}
      else
        (email_address,email_domain) = campus_email_address.split('@')
        email_domain_parts = email_domain.split('.')
        if(email_domain == 'extension.org')
          # look for an alias
          if(ea = EmailAlias.where(aliasable_type: 'Person').where(mail_alias: email_address).first)
            p = ea.aliasable
            match_hash =  {'match' => 'yes',
                           'people_id' => p.id,
                           'people_idstring' => p.idstring,
                           'people_email' => p.email,
                           'people_name' => p.fullname}
          end
        elsif(email_domain_parts.last =~ %r{edu|mil|gov|com})
          base_domain = "#{email_domain_parts.reverse[1]}.#{email_domain_parts.reverse[0]}"
          if(p = Person.where(first_name: first_name).where(last_name: last_name).where("email LIKE '%#{base_domain}%'").first)
            match_hash =  {'match' => 'maybe',
                           'people_id' => p.id,
                           'people_idstring' => p.idstring,
                           'people_email' => p.email,
                           'people_name' => p.fullname}
          end
        end
      end
      match_hash
    end
  end

  desc "match_from_file", "All daily cron tasks"
  method_option :environment,:default => 'production', :aliases => "-e", :desc => "Rails environment"
  method_option :input_file, :aliases => "-i", :desc => "Import File", :required => true
  method_option :output_file, :aliases => "-o", :desc => "Output File (default is input file + '_matched')"
  def match_from_file
    load_rails(options[:environment])
    input_file = File.expand_path(options[:input_file])
    if(!File.exists?(input_file))
      say("The specified input file #{input_file} does not exist!")
      exit(1)
    end

    if(!File.extname(input_file) == ".csv")
      say("Please provide an input file that is a CSV-format file ending in .csv")
      exit(1)
    end

    match_hash = {}
    line_number = 0
    match_stats = {total: 0, yes: 0, maybe: 0, no: 0}

    # process input file
    CSV.foreach(input_file,headers: true) do |row|
      line_number += 1
      say("Processing Line ##{line_number}... ")
      rowhash = row.to_hash
      campus_id = rowhash['id']
      match_hash[campus_id] = rowhash
      matched_data = match_test(rowhash)
      match_stats[:total] += 1
      case matched_data['match']
      when 'no'
        match_stats[:no] += 1
        say("No match.")
      when 'yes'
        match_stats[:yes] += 1
        say("Match!")
      when 'maybe'
        match_stats[:maybe] += 1
        say("Possible match.")
      end
      match_hash[campus_id].merge!(matched_data)
    end # input_file

    say("Match statistics:")
    say(" Total:            #{match_stats[:total]}")
    say(" Not Matched:      #{match_stats[:no]}")
    say(" Matched:          #{match_stats[:yes]}")
    say(" Possible Matches: #{match_stats[:maybe]}")

    output_filedir = File.dirname(input_file)
    output_basename = File.basename(input_file,".csv") + "_matched"
    output_file = "#{output_filedir}/#{output_basename}.csv"
    say("Writing match results to #{output_file}")

    CSV.open(output_file,'wb') do |csv|
      headers = ['id','username','email','firstname','lastname','match','people_id','people_idstring','people_email','people_name']
      csv << headers
      match_hash.each do |campus_id,values|
        row = []
        headers.each do |field|
          row << match_hash[campus_id][field]
        end
        csv << row
      end
    end
  end
end

CampusDataMatch.start
