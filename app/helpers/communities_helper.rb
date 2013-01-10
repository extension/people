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

  def community_connection_for_person_for_list(community,person)
    connection = person.connection_with_community(community)
    if(community.is_institution?)
      case connection
      when 'invitedleader'
        displaytext = 'You are have been invited to join the institutional team for this institution.'
      when 'invitedmember'
        displaytext = 'You are have been invited to join this institution.'
      when 'member'
        displaytext = 'You are a member of this institution.'
      when 'leader'
        displaytext = 'You are on the institutional team at this institution.'
      when 'pending'
        displaytext = 'Your membership in this institution is pending approval.'
      end
    else
      case connection
      when 'invitedleader'
        displaytext = 'You are have been invited to join this community as a leader.'
      when 'invitedmember'
        displaytext = 'You are have been invited to join this community.'
      when 'member'
        displaytext = 'You are a member of this community.'
      when 'leader'
        displaytext = 'You are a leader of this community.'
      when 'pending'
        displaytext = 'Your membership in this community is pending approval.'
      end
    end
    
    if(displaytext)
      "<p>#{displaytext}</p>".html_safe
    end
  end


end