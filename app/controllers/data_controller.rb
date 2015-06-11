# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
class DataController < ApplicationController
  skip_before_filter :signin_required, :check_hold_status

  def groups
    if params[:term]
      like= "%".concat(params[:term].concat("%"))
      groups = Group.launched.where("name like ?", like)
    else
      groups = Group.all
    end
    list = groups.map {|g| Hash[ id: g.id, label: g.name, name: g.name]}
    render json: list
  end


  def publicprofile
    person_id = params[:person_id] || params[:person]
    if(person_id.blank?)
      returnhash = {:success => false, :errormessage => 'Invalid parameters.'}
      return render :text => returnhash.to_json
    end

    @person = Person.find_by_email_or_idstring_or_id(person_id,false)
    if(@person.nil?)
      returnhash = {:success => false, :errormessage => 'No such user.'}
      return render :text => returnhash.to_json
    end

    public_attributes = @person.public_attributes
    social_networks = []
    @person.social_networks_plus.where('is_public = ?',true).each do |network|
      social_networks << {:accountid => network.accountid, :network => network.name, :displayname => network.display_name, :accounturl => network.accounturl}
    end

    if(public_attributes[:profile_attributes].blank?)
      returnhash = {:success => false, :errormessage => 'No public attributes'}
      return render :text => returnhash.to_json
    else
      returnhash = public_attributes[:profile_attributes].merge({:social_networks => social_networks, :success => true})
      return render :text => returnhash.to_json
    end
  end

  def communitymembers
    community_id = params[:community_id] || params[:community]
    if(community_id.blank?)
      returnhash = {:success => false, :errormessage => 'Invalid parameters.'}
      return render :text => returnhash.to_json
    end

    @community = Community.find_by_shortname_or_id(community_id,false)
    if(@community.nil?)
      returnhash = {:success => false, :errormessage => 'No such community.'}
      return render :text => returnhash.to_json
    end
   
    returnhash = {:success => true, :total_joined => @community.joined.count, :has_public_data => 0, :person_list => {}}  
    @community.joined.each do |person|
      public_attributes = person.public_attributes
      social_networks = []
      person.social_networks_plus.where('is_public = ?',true).each do |network|
        social_networks << {:accountid => network.accountid, :network => network.name, :displayname => network.display_name, :accounturl => network.accounturl}
      end
      if(!public_attributes[:profile_attributes].blank?)
        returnhash[:has_public_data] += 1
        returnhash[:person_list][person.idstring] = public_attributes[:profile_attributes].merge({:social_networks => social_networks})
      end
    end

    # add in the community information
    community_info = {}
    community_info[:name] = @community.name
    community_info[:entrytype] = @community.entrytype_to_s 
    if(!@community.shortname.blank?)
      community_info[:shortname] = @community.shortname
    end
    if(!@community.description.blank?)
      community_info[:description] = @community.description
    end
    community_info[:publishing_community] = @community.publishing_community?
    
    returnhash[:community_info] = community_info

    return render :text => returnhash.to_json
  end


end
