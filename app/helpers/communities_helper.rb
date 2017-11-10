# === COPYRIGHT:
# Copyright (c) North Carolina State University
# === LICENSE:
# see LICENSE file
module CommunitiesHelper

  def community_masthead(community, options = {})
    image_size = options[:image_size] || :large

    if(!community.community_masthead.present?)
      image_tag("community-masthead-placeholder.png", :title => community.name).html_safe
    else
      image_tag(community.community_masthead_url(image_size), :title => community.name).html_safe
    end
  end

  def connection_nav_item(label,connection)
    if(!params['connection'] and connection == 'joined')
      list_item_class = " class='active'"
    else
      list_item_class = ((params[:connection] == connection) ? " class='active'" : '')
    end
    "<li#{list_item_class}>#{link_to(label,connections_community_path(@community,connection: connection))}</li>".html_safe
  end

  def link_to_community(community,options = {})
    nolink = options[:nolink] || false

    if community.nil?
      '[unknown community]'
    elsif(nolink)
      "#{community.name}"
    else
      link_to(community.name,community_path(community)).html_safe
    end
  end

  def display_invited_as(connectiontype)
    case connectiontype
    when 'invitedleader'
      'Leader'
    when 'invitedmember'
      'Member'
    else
      ''
    end
  end

  def description_for_community(community)
    if(community.description.blank?)
      '<em>No description provided</em>'.html_safe
    else
      community.description.html_safe
    end
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



  def join_community_text(community)
    community.is_institution? ? 'Join Institution' : 'Join Community'
  end

  def leave_community_text(community)
    community.is_institution? ? 'Leave Institution' : 'Leave Community'
  end

  def join_community_link(community)
    link_to(join_community_text(@community),join_community_path, :class => "btn btn-default btn-primary btn-sm", :remote => true, :method => :post).html_safe
  end

  def leave_community_link(community)
    link_to(leave_community_text(@community),leave_community_path, :class => "btn btn-default btn-sm", :remote => true, :method => :post).html_safe
  end

  def change_connection_link(community,person,connectiontype)
    case connectiontype
    when 'leader'
      label = community.is_institution? ? 'add&nbsp;to&nbsp;institutional&nbsp;team'.html_safe : 'make&nbsp;leader'.html_safe
    when 'member'
      label = 'make&nbsp;member'.html_safe
    when 'invitedleader'
      label = community.is_institution? ? 'invite&nbsp;to&nbsp;institutional&nbsp;team'.html_safe : 'invite&nbsp;as&nbsp;leader'.html_safe
    when 'invitedmember'
      label = 'invite&nbsp;as&nbsp;member'.html_safe
    else
      return ''
    end
    link_to(label,change_connection_community_path(id: community.id, person_id: person.id, connectiontype: connectiontype), class: 'btn btn-default btn-sm', remote: true, method: :post).html_safe
  end

  def remove_connection_link(community,person)
    link_to('remove',remove_connection_community_path(id: community.id, person_id: person.id), class: 'btn btn-default btn-sm', remote: true, method: :post).html_safe
  end

  def get_communitytypes_for_select
    returnarray = []
    Community::ENTRYTYPE_LABELS.keys.sort.each do |key|
      returnarray << [I18n.translate("communities.entrytypes.#{Community::ENTRYTYPE_LABELS[key]}"),key]
    end
    returnarray
  end

  def get_membershiplevels_for_select
    returnarray = []
    Community::MEMBERSHIPLEVEL_LABELS.keys.sort.each do |key|
      returnarray << ["#{Community::MEMBERSHIPLEVEL_LABELS[key].capitalize}",key]
    end
    returnarray
  end


  def community_icon(community)
    if(community.is_institution?)
      "<i class='fa fa-building-o'></i>".html_safe
    else
      "<i class='fa fa-group'></i>".html_safe
    end
  end


end
