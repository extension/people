# === COPYRIGHT:
# Copyright (c) North Carolina State University
# === LICENSE:
# see LICENSE file
module CommunitiesHelper

  def display_invited_as(connectioncode)
    case connectioncode
    when CommunityConnect::INVITED_LEADER
      'Leader'
    when CommunityConnect::INVITED_MEMBER
      'Member'
    else
      ''
    end
  end

  def primary_institution_name_for_person(person, niltext = 'not specified')
    if(institution = person.primary_institution)
      institution.name
    else
      niltext.html_safe
    end
  end

  def community_connection_for_person(community,person)
    connection = person.connection_with_community(community)
    case connection
    when 'invitedleader'
      locale_key = (community.is_institution? ? 'invitedleader_institution' : 'invitedleader')
    when 'leader'
      locale_key = (community.is_institution? ? 'institutional_team' : 'leader')
    else
      locale_key = connection
    end
    I18n.translate("communities.connections.#{locale_key}")     
  end    

end