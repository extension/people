# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class PeopleController < ApplicationController
  #   skip_before_filter :check_hold_status , personal profile/edit
  before_filter :set_tab

  def show
    @person = Person.find(params[:id])
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
    if params[:explanation].nil? or params[:explanation].empty?
      flash[:failure] = 'An explanation for vouching for this eXtensionID is required'
      return redirect_to(person_url(@person))
    else
      if(@person.vouch({voucher: current_person, explanation: params[:explanation], ip_address: request.remote_ip}))
        flash[:success] = "Vouched for #{@person.fullname}"
        return redirect_to(person_url(@person))
      else
        flash[:failure] = 'Failed to vouch for user, reported status may not be correct'
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

  # def password
  #   #TODO
  # end

  private

  def set_tab
    @selected_tab = 'colleagues'
  end


end

