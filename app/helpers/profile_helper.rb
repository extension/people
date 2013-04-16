# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file

module ProfileHelper

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

  def add_social_network_link(network)
    link_to("add",'#', :onclick => "$('#rankingattributes').append('#{escape_javascript(render(:partial => 'ranking_attribute',:locals => {:attributename => attributename}))}')").html_safe
  end

end
