# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file
class PeopleController < ApplicationController
  skip_before_filter :check_hold_status, except: [:browse, :index, :vouch, :pendingreview, :invitations, :invite]
  before_filter :set_tab

  def show
    @person = Person.find_by_id_or_idstring(params[:id])
    if(@person != current_person)
      # manual check_hold_status
      return redirect_to home_pending_url if (!current_person.activity_allowed?)
    end    
  end

  def edit
    @person = Person.find(params[:id])
    if(@person != current_person)
      # manual check_hold_status
      return redirect_to home_pending_url if (!current_person.activity_allowed?)
    end
  end

  def update
    @person = Person.find(params[:id])
    if(current_person != @person and !current_person.is_admin? )
      update_params = params[:person].reject{|attribute,value| attribute == 'email'}
    else
      update_params = params[:person]
    end

    if @person.update_attributes(params[:person])
      what_changed = @person.previous_changes.reject{|attribute,value| ['updated_at'].include?(attribute)}
      @person.check_profile_changes({colleague_id: current_person.id, ip_address: request.remote_ip})

      if(current_person == @person)
        Activity.log_activity(person_id: @person.id, 
                              activitycode: Activity::UPDATE_PROFILE, 
                              ip_address: request.remote_ip, 
                              additionaldata: {what_changed: what_changed})  
      else
        # notification
        Notification.create(notifiable: @person, 
                            notification_type: Notification::UPDATE_COLLEAGUE_PROFILE, 
                            additionaldata: {what_changed: what_changed, colleague_id: current_person.id})

        # activity log
        Activity.log_activity(person_id: @person.id, 
                              activitycode: Activity::UPDATE_COLLEAGUE_PROFILE, 
                              ip_address: request.remote_ip,
                              colleague_id: current_person.id, 
                              additionaldata: {what_changed: what_changed})
      end          

      return redirect_to(@person, :notice => 'Profile was updated.')
    else
      render :action => 'edit'
    end
  end

  def index
  end

  def browse
    if(params[:filter] and @browse_filter = BrowseFilter.find_by_id(params[:filter]))
      @browse_filter_objects = @browse_filter.settings_to_objects

      if(!params[:download].nil? and params[:download] == 'csv')
        @colleagues = Person.display_accounts.filtered_by(@browse_filter).order('last_name ASC')
        send_data(meta_contributions_csv(@colleagues),
                  :type => 'text/csv; charset=iso-8859-1; header=present',
                  :disposition => "attachment; filename=colleagues_filtered_by_filter#{@browse_filter.id}.csv")
      else
        @colleagues = Person.display_accounts.filtered_by(@browse_filter).page(params[:page]).order('last_name ASC')
      end
    else
      @colleagues = Person.display_accounts.page(params[:page]).order('last_name ASC')
    end
  end

  def filter
    if(browse_filter = BrowseFilter.find_or_create_by_settings(params,current_person))
      return redirect_to(browse_people_url(filter: browse_filter.id))      
    else
      flash[:warning] = 'Invalid filter provided.'
      return redirect_to(browse_people_url)
    end
  end

  def find
    if (!params[:q].blank?) 
      @colleagues = Person.patternsearch(params[:q]).order('last_name,first_name').page(params[:page])
      if @colleagues.blank?
        flash[:warning] = "No colleagues were found that matched your search term"
      end
    end
  end  

  def pendingreview
    @colleagues = Person.pendingreview.order('updated_at DESC').page(params[:page])
  end

  def vouch
    @person = Person.find(params[:id])
    if params[:explanation].blank?
      flash[:failure] = 'An explanation for vouching for this eXtensionID is required'
      return redirect_to(person_url(@person))
    else
      if(@person.vouch({voucher: current_person, explanation: params[:explanation], ip_address: request.remote_ip}))
        flash[:success] = "Vouched for #{@person.fullname}"
        return redirect_to(person_url(@person))
      else
        flash[:failure] = "Failed to vouch for #{@person.first_name}, reported status may not be correct"
        return redirect_to(person_url(@person))
      end
    end
  end

  def invitations
    @invitations = Invitation.includes(:person).pending.order('created_at DESC').page(params[:page])
  end

  def invite
    @invite_communities = current_person.invite_communities
    if(request.post?)
      @invitation = Invitation.new(params[:invitation])

      # check for existing person with same email
      if(person = Person.find_by_email(@invitation.email))
        @invitation.errors.add(:base, "#{view_context.link_to(person.fullname, person_path(person))} already has an eXtensionID".html_safe)
        return render
      end

      @invitation.person = current_person
      if(@invitation.save)
        Activity.log_activity(person_id: current_person.id, activitycode: Activity::INVITATION, additionalinfo: @invitation.email, additionaldata: {'invitation_id' => @invitation.id}, ip_address: request.remote_ip)
        return render(template: 'people/sentinvite')
      end
    else
      @invitation = Invitation.new()
    end
  end

  def retire
    @person = Person.find(params[:id])
    if(@person != current_person)
      # manual check_hold_status
      return redirect_to home_pending_url if (!current_person.activity_allowed?)
    end

    if(request.post?)
      if((current_person != @person) and (params[:explanation].blank?))
        flash[:failure] = 'An explanation for retiring this account is required'
      else
        if(@person.retire({colleague: current_person, explanation: params[:explanation], ip_address: request.remote_ip}))
          flash[:success] = "Retired the account for #{@person.fullname}"
          return redirect_to(person_url(@person))
        else
          flash[:failure] = 'Failed to retire the account, reported status may not be correct'
          return redirect_to(person_url(@person))
        end
      end
    end
  end

  def restore
    @person = Person.find(params[:id])

    if(@person != current_person)
      # manual check_hold_status
      return redirect_to home_pending_url if (!current_person.activity_allowed?)
    end

    if(@person.restore({colleague: current_person, ip_address: request.remote_ip}))
      flash[:success] = "Restored the account for #{@person.fullname}"
      return redirect_to(person_url(@person))
    else
      flash[:failure] = 'Failed to restore the account, reported status may not be correct'
      return redirect_to(person_url(@person))
    end
  end

  def password
    @person = Person.find_by_id_or_idstring(params[:id])
    return redirect_to(person_url(current_person)) if(@person != current_person)
    if(request.post?)
      if(!params[:person])
        @person.errors.add(:base, "Missing parameters".html_safe)
      elsif(!params[:person][:current_password])
        @person.errors.add(:current_password, "You must include your current password".html_safe)
      elsif(!@person.check_password(params[:person][:current_password]))
        @person.errors.add(:current_password, "Your current password is not correct".html_safe)
      elsif(!params[:person][:password] or params[:person][:password].length < 8)
        @person.errors.add(:password, "Your new password must be a minimum of 8 characters".html_safe)
      else
        @person.password = params[:person][:password]
        if(@person.set_hashed_password(save: true))
        Activity.log_activity(person_id: @person.id, 
                              activitycode: Activity::PASSWORD_CHANGE, 
                              ip_address: request.remote_ip)            
          flash[:notice] = 'Your password has been changed'
          return redirect_to(person_url(current_person))
        end
      end
    end
  end


  def change_public_setting
    @public_setting = ProfilePublicSetting.find(params[:id])
    if (@public_setting.person == current_person)
      if(!params[:is_public].nil? and params[:is_public] == 'yes')
        @public_setting.update_attributes({:is_public => true})
      else
        @public_setting.update_attributes({:is_public => false})
      end
    end
  end
  
  def change_social_network_publicity
    @social_network_connection = SocialNetworkConnection.find(params[:id])
    if (@social_network_connection.person == current_person)
      if(!params[:is_public].nil? and params[:is_public] == 'yes')
        @social_network_connection.update_attributes({:is_public => true})
      else
        @social_network_connection.update_attributes({:is_public => false})
      end
    end
    @social_network = current_person.social_networks.where("social_network_connections.id = #{@social_network_connection.id}").first
  end
  
  def public_settings
    @person = Person.find_by_id_or_idstring(params[:id])
    return redirect_to(person_url(current_person)) if(@person != current_person)

    # this is a bit of an odd way of doing this, but this guarrantees 
    # we have a db entry for all the settings for the person.
    @publicsettings = []
    ProfilePublicSetting::KNOWN_ITEMS.each do |item|
      @publicsettings << ProfilePublicSetting.find_or_create_by_person_and_item(current_person,item)
    end
  end

  def change_social_networks
    @socialnetworks = SocialNetwork.active.where("id <> ?",SocialNetwork::OTHER_NETWORK).order(:display_name).all
    @socialnetworks << SocialNetwork.find_by_id(SocialNetwork::OTHER_NETWORK)
  end

  def edit_social_network
    if(request.get?)
      if(params[:network_connection])
        @social_network_connection = SocialNetworkConnection.find(params[:network_connection])

        # ownership check
        if(@social_network_connection.person_id != current_person.id)
          flash[:warning] = 'Unable to edit this social network connection.'
          return redirect_to(change_social_networks_people_url)
        end

      elsif(params[:network])
        @social_network = SocialNetwork.find(params[:network])
        @social_network_connection = SocialNetworkConnection.new(social_network: @social_network)
      else
        flash[:warning] = 'Missing parameters'
        return redirect_to(change_social_networks_people_url)
      end

    elsif(request.post?)
      if(params[:social_network_connection_id])
        @social_network_connection = SocialNetworkConnection.find(params[:social_network_connection_id])

        # ownership check
        if(@social_network_connection.person_id != current_person.id)
          flash[:warning] = 'Unable to edit this social network connection.'
          return redirect_to(change_social_networks_people_url)
        end

        update_attributes = params[:social_network_connection].merge({person_id: current_person.id})
        if(@social_network_connection.update_attributes(update_attributes))

          Activity.log_activity(person_id: current_person.id, 
                                activitycode: Activity::UPDATE_SOCIAL_NETWORKS, 
                                ip_address: request.remote_ip, 
                                additionalinfo: "updated #{@social_network_connection.social_network.name}",  
                                additionaldata: {updated: @social_network_connection.attributes.to_yaml})   

          flash[:success] = 'Social network updated.'
          return redirect_to(change_social_networks_people_url)
        end
      elsif(params[:social_network_connection] and params[:social_network_connection][:social_network_id])
        @social_network = SocialNetwork.find(params[:social_network_connection][:social_network_id])
        save_attributes = params[:social_network_connection].merge({person_id: current_person.id, social_network: @social_network})
        if(@social_network_connection = SocialNetworkConnection.create(save_attributes))
          Activity.log_activity(person_id: current_person.id, 
                                activitycode: Activity::UPDATE_SOCIAL_NETWORKS, 
                                ip_address: request.remote_ip,
                                additionalinfo: "added #{@social_network_connection.social_network.name}",  
                                additionaldata: {added: @social_network_connection.attributes.to_yaml})   
          flash[:success] = 'Social network added.'
          return redirect_to(change_social_networks_people_url)
        end
      else
        flash[:warning] = 'Missing parameters'
      end    

    end


  end

  def delete_social_network
    if(!params[:network_connection])
      flash[:warning] = 'Missing parameters'
      return redirect_to(change_social_networks_people_url)
    elsif(@social_network_connection = SocialNetworkConnection.find_by_id(params[:network_connection]))
      if(@social_network_connection.person_id != current_person.id)
        flash[:warning] = 'Unable to remove this social network connection.'
        return redirect_to(change_social_networks_people_url)
      else
        Activity.log_activity(person_id: current_person.id, 
                              activitycode: Activity::UPDATE_SOCIAL_NETWORKS, 
                              ip_address: request.remote_ip,
                              additionalinfo: "deleted #{@social_network_connection.social_network.name}", 
                              additionaldata: {removed: @social_network_connection.attributes.to_yaml})          
        @social_network_connection.destroy
        flash[:success] = 'Social network removed.'
        return redirect_to(change_social_networks_people_url)
      end
    else
      flash[:warning] = 'Invalid parameters'
      return redirect_to(change_social_networks_people_url)
    end
  end

  def activity
    @activities = Activity.public_activity.order('created_at DESC').page(params[:page])
  end

  private

  def set_tab
    @selected_tab = 'colleagues'
  end

# # eXtensionID,First Name,Last Name,Email,Phone,Title,Position,Institution,Other Affiliation,Location,County,Agreement Status,Account Created
# # <% for showuser in @userlist %><%= makeusercsvstring(showuser)+"\n" %><% end %>

#   def colleagues_csv(colleagues)
#     CSV.generate do |csv|
#       headers = []
#       headers << 'First Name'
#       headers << 'Last Name'
#       headers << 'idstring'
#       headers << 'Email'
#       headers << 'Phone'
#       headers << 'Title'
#       headers << 'Position'
#       headers << 'Institution'
#       headers << 'Other Affiliation'
#       headers << 'Location'
#       headers << 'County'
#       headers << 'Agreement Status'
#       headers << 'Account Created'
#       headers << 'Last Active At'
#       headers << 'Communities'
#       csv << headers
#       colleagues.each do |person|
#         row = []
#         row << person.first_name
#         row << person.last_name
#         row << person.idstring
#         row << person.email
#         row << person.phone
#         row << person.title
#         row << (person.position.blank? ? '' : person.position.name)
#         row << (person.institution.blank? ? '' : person.institution.name)
#         row << person.affiliation
#         csv << row
#       end
#     end
#   end  


end

