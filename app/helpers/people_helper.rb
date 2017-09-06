# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file

module PeopleHelper

  def institution_text(person)
    text = []
    if(person.institution)
      text << person.institution.name
    end
    if(person.affiliation)
      text << person.affiliation
    end
    text.join(', ')
  end


  def link_to_person(person,options = {})
    show_blank = options[:show_blank] || false
    show_unknown = options[:show_unknown] || false
    show_systemuser = options[:show_systemuser] || false
    nolink = options[:nolink] || false

    if person.nil?
      if(show_blank)
        '&nbsp'.html_safe
      else
        show_unknown ? 'Unknown' : 'System'
      end
    elsif(person.id == 1 and !show_systemuser)
      'System'
    elsif(nolink)
      "#{person.fullname}"
    else
      link_to(person.fullname,person_path(person),class: 'person').html_safe
    end
  end

  def person_avatar(person, options = {})
    image_size = options[:image_size] || :thumb
    case image_size
      when :large     then image_size_in_px = "300x300"
      when :medium    then image_size_in_px = "100x100"
      when :thumb     then image_size_in_px = "50x50"
    end

    is_private = (!current_person && !person.profile_setting_is_public?('avatar'))

    if(person.is_systems_account?)
      image_tag("engbot.png", :class => 'avatar size' + image_size_in_px, :size => image_size_in_px, :title => 'private profile').html_safe
    elsif(is_private)
      image_tag("avatar_private_w_lock.png", :class => 'avatar size' + image_size_in_px, :size => image_size_in_px, :title => 'private profile').html_safe
    elsif(!person.avatar.present?)
      image_tag("avatar_placeholder.png", :class => 'avatar size' + image_size_in_px, :size => image_size_in_px, :title => person.fullname).html_safe
    else
      image_tag(person.avatar_url(image_size), :class => 'avatar size' + image_size_in_px, :title => person.fullname).html_safe
    end
  end

  def link_to_person_avatar(person, options = {})
    nolink = options[:nolink] || false
    if(current_person)
      link_path = person_path(person)
    else
      link_path = public_profile_path(person.idstring)
    end

    private_name = !@currentperson and person.public_attributes[:profile_attributes].blank?
    if(private_name)
      link_title = "Private profile"
    else
      link_title = person.fullname
    end

    if(nolink)
      return person_avatar(person,options)
    else
      return link_to(person_avatar(person,options), link_path, :title => link_title).html_safe
    end
  end

  def link_to_person_profile(person, options = {})
    nolink = options[:nolink] || false
    if(current_person)
      link_path = person_path(person)
    else
      link_path = public_profile_path(person.idstring)
    end

    private_name = (!current_person && person.public_attributes[:profile_attributes].blank?)
    if(private_name)
      link_title = "Private profile"
    else
      link_title = person.fullname
    end

    if(nolink)
      return person_avatar(person,options)
    else
      return link_to(link_title, link_path, :title => link_title).html_safe
    end
  end



  def social_network_url(network_and_connection)
    if(!network_and_connection.accounturl.blank?)
      begin
        accounturi = URI.parse(URI.escape(network_and_connection.accounturl))
      rescue
        return nil
      end
      if(accounturi.scheme.nil?)
        uristring = 'http://'+network_and_connection.accounturl
      else
        uristring = network_and_connection.accounturl
      end
      return uristring
    else
      return nil
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
      return "<span class='social_network_link'>#{network_icon(network_and_connection.name)} <a href=\"#{uristring}\">#{network_and_connection.accountid}</a></span>".html_safe
    else
      return "<span class='social_network_link'>#{network_icon(network_and_connection.name)} #{network_and_connection.accountid}</span>".html_safe
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

    if(activity.person_id.blank? and activity.activitycode == Activity::AUTH_LOCAL_FAILURE)
      # special case of showing additional information for authentication failures
      text_macro_options[:persontext]  = hide_person_text ? '' : "#{activity.additionalinfo} (unknown account) "
    else
      text_macro_options[:persontext]  = hide_person_text ? '' : "#{link_to_person(activity.person,{nolink: nolink})} "
    end

    if(activity.activitycode == Activity::AUTH_REMOTE_SUCCESS)
      text_macro_options[:site] =  activity.site
    end


    text_macro_options[:communitytext]  = hide_community_text ? 'community' : "#{link_to_community(activity.community,{nolink: nolink})} community"
    text_macro_options[:colleaguetext] =  "#{link_to_person(activity.colleague,{nolink: nolink, show_unknown: true})}"

    if(activity.activitycode == Activity::INVITATION)
      text_macro_options[:emailaddress] =  activity.additionalinfo
    end

    if(activity.activitycode == Activity::EMAIL_CHANGE)
      text_macro_options[:current_email] =  (activity.person.email || 'unknown')
      text_macro_options[:previous_email] =  (activity.person.previous_email || 'unknown')
    end

    I18n.translate("activity.#{activity.activitycode_to_s}",text_macro_options).html_safe

  end

  def status_icon(person)
    if(person.is_signup?)
      icon = "<i class='fa fa-info-circle'></i>".html_safe
      title = 'Pending email confirmation from signup'
      link_to(icon,'#',data: {toggle: "tooltip"},title: title, class: 'status_icon').html_safe
    elsif(person.retired?)
      icon = "<i class='fa fa-info-circle'></i>".html_safe
      title = 'Retired account.'
      link_to(icon,'#',data: {toggle: "tooltip"},title: title, class: 'status_icon').html_safe
    elsif(person.pendingreview?)
      icon = "<i class='fa fa-info-circle'></i>".html_safe
      title = 'Pending review.'
      link_to(icon,'#',data: {toggle: "tooltip"},title: title, class: 'status_icon').html_safe
    elsif(!person.email_confirmed?)
      icon = "<i class='fa fa-info-circle'></i>".html_safe
      title = 'Pending email confirmation from email change'
      link_to(icon,'#',data: {toggle: "tooltip"},title: title, class: 'status_icon').html_safe
    elsif(person.last_activity_at.nil?)
      icon = "<i class='fa fa-clock-o'></i>".html_safe
      title = "Has never been active"
      link_to(icon,'#',data: {toggle: "tooltip"},title: title, class: 'status_icon').html_safe
    elsif(person.is_inactive?)
      icon = "<i class='fa fa-clock-o'></i>".html_safe
      title = "Has not been active since #{person.last_activity_at.strftime("%Y/%m/%d")}"
      link_to(icon,'#',data: {toggle: "tooltip"},title: title, class: 'status_icon').html_safe
    else
      '&nbsp;'.html_safe
    end
  end

  def status_class(person)
    if(person.retired?)
      'retired'
    elsif(person.is_inactive?)
      'inactive'
    else
      'active'
    end
  end

  def tou_status(person)
    if(person.tou_accepted_at.nil?)
      status_text = "Not Yet Accepted"
      date_text = ''
    else
      status_text = "Accepted"
      date_text = "(#{display_time(person.tou_accepted_at)})"
    end

    if(current_person and (current_person == person))
     "#{link_to(status_text,accounts_tou_notice_path).html_safe} #{date_text}".html_safe
    else
     "#{status_text} #{date_text}".html_safe
    end
  end


end
