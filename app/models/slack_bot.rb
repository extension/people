# === COPYRIGHT:
# Copyright (c) 2014 North Carolina State University
# === LICENSE:
# see LICENSE file

class SlackBot < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  default_url_options[:host] = Settings.urlwriter_host

  attr_accessor   :message, :post_to_room
  attr_accessible :slack_channel_id, :slack_channel_name, :slack_user_id, :slack_user_name, :command, :commandtext

  SLACKBOT_ACTIONS = ['find','help']

  after_create :process_commandtext

  def queue_slackpost
    if(Settings.redis_enabled)
      self.class.delayed_slackpost(self.id)
    else
      self.slackpost
    end
  end

  def self.delayed_slackpost(record_id)
    if(record = find_by_id(record_id))
      record.slackpost
    end
  end


  def slackpost
    commands = parse_commandtext
    action = commands[:action]
    commandterms = commands[:commandterms]
    case action
    when 'find'
      return self.slackpost_find
    else
      # nothing
      return true
    end
  end

  def parse_commandtext
    commandterms = self.commandtext.split(/\s+/).compact.uniq.reverse
    # remove nils, duplicates, and reverse it, so we can pop the action off
    action = commandterms.pop
    {action: action, commandterms: commandterms}
  end

  def process_commandtext
    commands = parse_commandtext
    action = commands[:action]
    commandterms = commands[:commandterms]
    if(!SLACKBOT_ACTIONS.include?(action))
      return self.help
    end

    case action
    when 'find'
      return self.find
    when 'help'
      return self.help
    else
      return self.help
    end
  end

  def find
    commands = parse_commandtext
    commandterms = commands[:commandterms]

    searchterm = commandterms.join(' ')
    searchcount = Person.patternsearch(searchterm).validaccounts.count
    if(searchcount == 0)
      returntext = "No one was found that matches your searchterm #{searchterm}"
    elsif(searchcount >= 10)
      self.queue_slackpost
      returntext = "I found #{searchcount} people that match your search. That's a lot of people! you may want to narrow your search"
    else
      self.queue_slackpost
      returntext = "I found #{searchcount} people that match your search. Results coming right up!"
    end
    return(self.message = returntext)
  end


  def help
    helptext = "The /people command queries https://people.extension.org for information\n"
    helptext += "Available subcommands are:\n"
    helptext += "/people find [searchterm]  : searches people for the name or idstring\n"
    return(self.message = helptext)
  end




  def slackpost_find
    commands = parse_commandtext
    commandterms = commands[:commandterms]
    searchterm = commandterms.join(' ')

    searchcount = Person.patternsearch(searchterm).validaccounts.count
    return true if searchcount == 0

    post_options = {}
    post_options[:channel] = "##{self.slack_channel_name}"
    post_options[:username] = "People Search Results"
    post_options[:icon_emoji] = ':engbot:'
    post_options[:message] = "Hi <@#{self.slack_user_id}|#{self.slack_user_name}>! Here are #{searchcount} people that match #{searchterm}"


    attachments = []
    Person.patternsearch(searchterm).validaccounts.all.each do |person|
      if(person.avatar.present?)
        avatar_url = person.avatar_url(:medium)
      else
        avatar_url = ApplicationController.helpers.asset_url('avatar_placeholder.png')
      end
      institution_list = []
      if(person.institution)
        institution_list << person.institution.name
      end
      if(person.affiliation)
        institution_list << person.affiliation
      end
      attachment = { "fallback" => "#{person.fullname} (#{person.idstring}) - #{person_url(person)} ",
        "title" => "#{person.fullname} (#{person.idstring})",
        "title_link" => "#{person_url(person)}",
        "text" => "#{person.title}\n#{institution_list.join(', ')}",
        "thumb_url" => "#{avatar_url}",
        "mrkdwn_in" => ["fields"],
        "fields" => [
          {
           "title" => "Biography",
           "value" => "#{(person.biography.blank? ? 'None listed' : Slack::Notifier::LinkFormatter.format(ReverseMarkdown.convert(person.biography)))}",
           "short" => false
          },
          {
            "title" => "Email",
            "value" =>  "#{person.email}",
            "short" =>  true
          },
          {
            "title" => "Last Active",
            "value" =>  "#{person.last_activity_at.strftime("%B %e, %Y, %l:%M %p %Z")}",
            "short" =>  true
          }
        ],
        "color" => "meh"
      }
      attachments << attachment
    end
    post_options[:attachments] = attachments

    SlackNotification.post(post_options)
  end

end
