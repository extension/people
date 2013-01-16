# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DataController < ApplicationController
  skip_before_filter :signin_required


  def counties_for_location
    if(find_location = params[:location])
      if(find_location.to_i > 0)
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

  
end