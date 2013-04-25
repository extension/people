# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file

module PeopleHelper

  def link_to_person(person,options = {})
    show_unknown = options[:show_unknown] || false
    show_systemuser = options[:show_systemuser] || false
    nolink = options[:nolink] || false

    if person.nil?
      show_unknown ? 'Unknown' : 'System'
    elsif(person.id == 1 and !show_systemuser)
      'System'
    elsif(nolink)
      "#{person.fullname}"
    else
      link_to(person.fullname,person_path(person),class: 'person').html_safe
    end
  end

  def social_network_link(network_and_connection)
    if(!network_and_connection.accounturl.blank?)
      begin
        accounturi = URI.parse(URI.escape(network_and_connection.accounturl))
      rescue
        return "#{network_icon(network_and_connection.name)} #{network_and_connection.accountid}".html_safe
      end
      if(accounturi.scheme.nil?)
        uristring = 'http://'+network_and_connection.accounturl
      else
        uristring = network_and_connection.accounturl
      end
      return "#{network_icon(network_and_connection.name)} <a href=\"#{uristring}\">#{network_and_connection.accountid}</a>".html_safe
    else
      return "#{network_icon(network_and_connection.name)} #{network_and_connection.accountid}".html_safe
    end
  end

  def network_icon(network_name)
    image_tag("/assets/socialnetworks/#{network_name}.png").html_safe
  end

  def institution_collection_for_edit(person)
    institutions = person.communities.institutions.connected_as('joined').order("name")
    institutions += (@person.location.blank? ? Community.institutions.order("name") : @person.location.communities.institutions.order("name"))
    institutions.uniq
  end

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
    # note space on the end of link - required in string formatting
    text_macro_options[:persontext]  = hide_person_text ? '' : "#{link_to_person(activity.person,{nolink: nolink})} "

    if([Activity::AUTH_REMOTE_SUCCESS,Activity::AUTH_REMOTE_FAILURE].include?(activity.activitycode))
      text_macro_options[:site] =  activity.site
    end


    text_macro_options[:communitytext]  = hide_community_text ? 'community' : "#{link_to_community(activity.community,{nolink: nolink})} community"

    if(!activity.colleague.nil?)
      text_macro_options[:colleaguetext] =  "#{link_to_person(activity.colleague,{nolink: nolink})}"
    end

    if(activity.activitycode == Activity::INVITATION)
      text_macro_options[:emailaddress] =  activity.additionalinfo
    end

    I18n.translate("activity.#{activity.activitycode_to_s}",text_macro_options).html_safe

  end

  def status_icon(person)
    if(person.is_signup?)
      icon = "<i class='icon-info-sign'></i>".html_safe
      title = 'Pending email confirmation from signup'
      link_to(icon,'#',data: {toggle: "tooltip"},title: title, class: 'status_icon').html_safe
    elsif(person.retired?)
      icon = "<i class='icon-info-sign'></i>".html_safe
      title = 'Retired account.'
      link_to(icon,'#',data: {toggle: "tooltip"},title: title, class: 'status_icon').html_safe
    elsif(person.pendingreview?)
      icon = "<i class='icon-info-sign'></i>".html_safe
      title = 'Pending review.'
      link_to(icon,'#',data: {toggle: "tooltip"},title: title, class: 'status_icon').html_safe
    elsif(!person.email_confirmed?)
      icon = "<i class='icon-info-sign'></i>".html_safe
      title = 'Pending email confirmation from email change'
      link_to(icon,'#',data: {toggle: "tooltip"},title: title, class: 'status_icon').html_safe    
    elsif(person.last_activity_at < (Time.zone.now - Settings.months_for_inactive_flag.months) )
      icon = "<i class='icon-time'></i>".html_safe
      title = "Has not been active since #{person.last_activity_at.strftime("%Y/%m/%d")}"
      link_to(icon,'#',data: {toggle: "tooltip"},title: title, class: 'status_icon').html_safe
    else
      '&nbsp;'.html_safe
    end
  end

  def status_class(person)
    if(person.retired?)
      'retired'
    elsif(person.last_activity_at < (Time.zone.now - Settings.months_for_inactive_flag.months))
      'inactive'
    else
      'active'
    end

  end 

end
