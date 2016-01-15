# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
module ApplicationHelper

  # at least until rails4
  def asset_url(asset)
    "https://#{Settings.urlwriter_host}/#{asset_path(asset)}"
  end

  def twitter_alert_class(type)
    baseclass = "alert"
    case type
    when :alert
      "#{baseclass} alert-warning"
    when :warning
      "#{baseclass} alert-warning"
    when :error
      "#{baseclass} alert-danger"
    when :failure
      "#{baseclass} alert-warning"
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

  def display_date(time)
    if(time.blank?)
      ''
    else
      time.strftime("%B %e, %Y")
    end
  end

  def navtab(tabtext,whereto)
    if(@selected_tab and @selected_tab == tabtext.downcase)
      "<li class='active'>#{link_to(tabtext,whereto)}</li>".html_safe
    else
      "<li>#{link_to(tabtext,whereto)}</li>".html_safe
    end
  end

  # code from: https://github.com/ripienaar/mysql-dump-split
  def humanize_bytes(bytes,defaultstring='')
    if(!bytes.nil? and bytes != 0)
      units = %w{B KB MB GB TB}
      e = (Math.log(bytes)/Math.log(1024)).floor
      s = "%.1f"%(bytes.to_f/1024**e)
      s.sub(/\.?0*$/,units[e])
    else
      defaultstring
    end
  end




end
