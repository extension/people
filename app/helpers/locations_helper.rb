# === COPYRIGHT:
# Copyright (c) North Carolina State University
# === LICENSE:
# see LICENSE file


module LocationsHelper

  def get_location_options
    locations = Location.find(:all, :order => 'entrytype, name')
    return locations.map{|l| [l.name, l.id]}
  end

  def get_county_options(provided_location = nil)
    if params[:location_id] && params[:location_id].strip != '' && location = Location.find(params[:location_id])
      counties = location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
      counties.map{|c| [c.name, c.id]}
    elsif(provided_location)
      counties = provided_location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
      counties.map{|c| [c.name, c.id]}
    end
  end

end
