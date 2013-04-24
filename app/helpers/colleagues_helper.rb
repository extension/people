# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file

module ColleaguesHelper


  def filter_text(filter_hash)
    string_array = []
    filter_hash.each do |filter_key,items|
      if(filter_key == 'social_networks')
        string_array << "<strong>Social Networks</strong>: #{items.map(&:display_name).join(' or ')}"        
      else  
        string_array << "<strong>#{filter_key.capitalize}</strong>: #{items.map(&:name).join(' or ')}"
      end
    end
    string_array.join(' and ').html_safe
  end

  def activity_to_s(activity,options = {})

    hide_community_text = options[:hide_community_text] || false
    hide_person_text = options[:hide_person_text] || false
    nolink = options[:nolink] || false

    text_macro_options = {}
    text_macro_options[:persontext]  = hide_person_text ? '' : "#{link_to_person(activity.person,{nolink: nolink})}"

    if([Activity::AUTH_REMOTE_SUCCESS,Activity::AUTH_REMOTE_FAILURE].include?(activity.activitycode))
      text_macro_options[:site] =  activity.site
    end


    text_macro_options[:communitytext]  = hide_person_text ? 'community' : "#{link_to_community(activity.community,{nolink: nolink})}"

    if(!activity.colleague.nil?)
      text_macro_options[:colleaguetext] =  "#{link_to_person(activity.colleague,{nolink: nolink})}"
    end

    if(activity.activitycode == Activity::INVITATION)
      text_macro_options[:emailaddress] =  activity.additionalinfo
    end

    I18n.translate("activity.#{activity.activitycode_to_s}",text_macro_options).html_safe

  end  

end