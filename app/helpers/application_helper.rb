# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
module ApplicationHelper

    def twitter_alert_class(type)
    baseclass = "alert"
    case type
    when :alert
      "#{baseclass} alert-warning"
    when :error
      "#{baseclass} alert-error"
    when :notice
      "#{baseclass} alert-info"
    when :success
      "#{baseclass} alert-success"
    else
      "#{baseclass} #{type.to_s}"
    end
  end

  def nav_item(path,label)
    list_item_class = current_page?(path) ? " class='active'" : ''
    "<li#{list_item_class}>#{link_to(label,path)}</li>".html_safe
  end


  def link_if_not_zero(count,label,path,htmloptions = {})
    if(count.to_i > 0)
      link_to(label,path,htmloptions).html_safe
    else
      label.html_safe
    end
  end

  def display_time(time)
    if(time.blank?)
      ''
    else
      time.strftime("%B %e, %Y, %l:%M %p %Z")
    end
  end


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
      link_to(person.fullname,person_path(person)).html_safe
    end
  end

  def navtab(tabtext,whereto)
    if(@selected_tab and @selected_tab == tabtext.downcase)
      "<li class='active'>#{link_to(tabtext,whereto)}</li>".html_safe
    else
      "<li>#{link_to(tabtext,whereto)}</li>".html_safe
    end
  end




end
