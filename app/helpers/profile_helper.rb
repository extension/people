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

  def institution_collection_for_edit(person)
    institutions = person.communities.institutions.connected_as('joined').order("name")
    institutions += (@person.location.blank? ? Community.institutions.order("name") : @person.location.communities.institutions.order("name"))
    institutions.uniq
  end

end
