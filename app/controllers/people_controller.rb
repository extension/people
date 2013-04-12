# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file
class PeopleController < ApplicationController
  skip_before_filter :check_hold_status, only: [:edit, :update]
  before_filter :set_tab

  def show
    @person = Person.find_by_id_or_idstring(params[:id])
  end

  def edit
    @person = Person.find(params[:id])
    # if @person != current_person
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
      @person.check_email_change({colleague_id: current_person.id, ip_address: request.remote_ip})

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
    if(@person.restore({colleague: current_person, ip_address: request.remote_ip}))
      flash[:success] = "Restored the account for #{@person.fullname}"
      return redirect_to(person_url(@person))
    else
      flash[:failure] = 'Failed to restore the account, reported status may not be correct'
      return redirect_to(person_url(@person))
    end
  end


  # def public
  #   #TODO
  # end

  # def account
  #   #TODO
  # end

  # def communities
  #   #TODO
  # end

  # def recent
  #   #TODO
  # end

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
          flash[:notice] = 'Your password has been changed'
          return redirect_to(person_url(current_person))
        end
      end
    end
  end

  private

  def set_tab
    @selected_tab = 'colleagues'
  end


end

