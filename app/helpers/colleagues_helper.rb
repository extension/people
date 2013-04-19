# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file

module ColleaguesHelper


  def filter_text(filter_hash)
    string_array = []
    filter_hash.each do |filter_key,items|
      if(filter_key == 'social_networks')
        string_array << "<strong>Social Networks</strong>: #{items.map(&:display_name).join(' or ')}"        
      else  
        string_array << "<strong>#{filter_key.capitalize}</strong>: #{items.map(&:name).join(' or ')}"
      end
    end
    string_array.join(' and ').html_safe
  end

end