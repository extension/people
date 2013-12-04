# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class LocationsController < ApplicationController
  skip_before_filter :signin_required, :check_hold_status


  def counties
    if(find_location = params[:location])
      if(find_location.cast_to_i > 0)
        location = Location.where(id: find_location).first
      end
      # TODO find by name or abbreviation if ever needed
    end

    if(location)
      counties = location.counties.order(:name).map{|county| Hash[id: county.id, name: county.name]}
    else
      counties = {}
    end
    render json: counties
  end



  def institutions
    if(find_location = params[:location])
      if(find_location.cast_to_i > 0)
        location = Location.where(id: find_location).first
      end
      # TODO find by name or abbreviation if ever needed
    end

    if(location)
      institutions = location.communities.institutions.order(:name).map{|institution| Hash[id: institution.id, name: institution.name]}
    else
      institutions = {}
    end
    render json: institutions
  end
  
end