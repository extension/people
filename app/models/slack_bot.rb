# === COPYRIGHT:
# Copyright (c) 2014 North Carolina State University
# === LICENSE:
# see LICENSE file

class SlackBot < ActiveRecord::Base

  attr_accessor   :message, :post_to_room
  attr_accessible :slack_channel_id, :slack_channel_name, :slack_user_id, :slack_user_name, :command, :commandtext

  SLACKBOT_ACTIONS = ['find','help']

  after_create :parse_commandtext

  def parse_commandtext
    commandterms = self.commandtext.split(/\s+/).compact.uniq.reverse
    # remove nils, duplicates, and reverse it, so we can pop the action off
    action = commandterms.pop
    if(!SLACKBOT_ACTIONS.include?(action))
      return self.help
    end

    # check for "room"
    if(commandterms.include?('room'))
      commandterms.reject!{|term| term == 'room'}
      self.post_to_room = true
    else
      self.post_to_room = false
    end

    case action
    when 'find'
      return self.find(commandterms)
    when 'help'
      return self.help
    else
      return self.help
    end
  end



  def help
    helptext = "The /people command queries https://people.extension.org for information\n"
    helptext += "Available subcommands are:\n"
    helptext += "/people find [searchterm]  : searches people for the name or idstring\n"
    helptext += " \n"
    helptext += "/engbot purpose search_string : searches the server purpose for search_string and returns all matching records\n"
    helptext += "    e.g. /engbot purpose rails\n"
    helptext += "/engbot hodor : returns a hodor heartbeat\n"
    return(self.message = helptext)
  end

end
