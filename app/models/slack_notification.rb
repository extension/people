# === COPYRIGHT:
# Copyright (c) North Carolina State University
# === LICENSE:
# see LICENSE file

class SlackNotification

  attr_accessor :message, :attachments, :slack, :icon_emoji

  def initialize(options = {})
    username = options[:username] || "EngBot"
    channel = options[:channel] || Settings.default_slack_channel
    @slack = Slack::Notifier.new(Settings.slack_webhook)
    @slack.username = username
    @slack.channel = channel
    @message = options[:message] || ''
    @attachments = options[:attachments]
    @icon_emoji = options[:icon_emoji]
    self
  end

  def post
    post_parameters = {}
    if(self.attachments.is_a?(Array))
      post_parameters[:attachments] = self.attachments
    else
      post_parameters[:attachments] = [self.attachments]
    end

    if(self.icon_emoji)
      post_parameters[:icon_emoji] = self.icon_emoji
    else
      post_parameters[:icon_emoji] = ':engbot:'
    end

    self.slack.ping(self.message, post_parameters)

  end

  def self.post(options = {})
    if(notification = self.new(options))
      notification.post
    end
  end

end
