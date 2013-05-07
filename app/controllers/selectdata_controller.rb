# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class SelectdataController < ApplicationController
  skip_before_filter :verify_authenticity_token


  def communities
    @communities = Community.where("name like ?", "%#{params[:q]}%")
    token_hash = @communities.collect{|community| {id: community.id, text: community.name}}
    render(json: token_hash)
  end

  def locations
    @locations = Location.where("name like ?", "%#{params[:q]}%")
    token_hash = @locations.collect{|location| {id: location.id, text: location.name}}
    render(json: token_hash)
  end  

  def positions
    @positions = Position.where("name like ?", "%#{params[:q]}%")
    token_hash = @positions.collect{|position| {id: position.id, text: position.name}}
    render(json: token_hash)
  end

  def social_networks
    @social_networks = SocialNetwork.active.where("name like ?", "%#{params[:q]}%")
    token_hash = @social_networks.collect{|network| {id: network.id, text: network.display_name}}
    render(json: token_hash)
  end    

  def interests
    @interests = Interest.used.where("name like ?", "#{params[:q]}%")
    token_hash = @interests.collect{|interest| {id: interest.id, text: interest.name}}
    render(json: token_hash)
  end    

end