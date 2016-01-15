# === COPYRIGHT:
# Copyright (c) North Carolina State University
# === LICENSE:
# see LICENSE file
class SlackbotController < ApplicationController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :signin_required, :check_hold_status


  def ask
    # verify token
    if(params[:token].blank? or params[:token] != Settings.slackbot_token)
      return render :text => 'Invalid Token', :status => :unprocessable_entity
    end

    if(slackbot = SlackBot.create(slack_channel_id: params[:channel_id],
                                  slack_channel_name: params[:channel_name],
                                  slack_user_id: params[:user_id],
                                  slack_user_name: params[:user_name],
                                  command: params[:command],
                                  commandtext: params[:text]))
      return render :text => slackbot.message, :status => :ok
    else
      # return object errors maybe, but not today
      return render :text => 'An error occurred processing your command', :status => :unprocessable_entity
    end
  end

end
