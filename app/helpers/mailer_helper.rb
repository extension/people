# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
module MailerHelper


  def mailer_logo
    logo_url = @mailer_cache.blank? ? "#{ssl_root_url}/email/logo_small.png" : "#{ssl_webmail_logo}" 
    image_tag(logo_url, alt: 'eXtension People').html_safe
  end

  def view_in_browser_link
    view_link = @mailer_cache.blank? ? '#' : webmail_view_url(hashvalue: @mailer_cache.hashvalue)
    link_to('View in a browser', view_link).html_safe
  end

  def profile_changes_text(changes)
    return_text_lines = []
    changes.each do |attribute,values|
      changed_from = values[0]
      changed_to = values[1]
      case attribute
      when 'position_id'
        display_attribute = 'position'
        display_from = blank_or_name(changed_from,'Position')
        display_to = blank_or_name(changed_to,'Position')
      when 'county_id'
        display_attribute = 'county'
        display_from = blank_or_name(changed_from,'County')
        display_to = blank_or_name(changed_to,'County')
      when 'location_id'
        display_attribute = 'location'
        display_from = blank_or_name(changed_from,'Location')
        display_to = blank_or_name(changed_to,'Location')        
      when 'institution_id'
        display_attribute = 'institution'
        display_from = blank_or_name(changed_from,'Community')
        display_to = blank_or_name(changed_to,'Community')
      else
        display_attribute = attribute
        display_from = blank_or_value(changed_from)
        display_to = blank_or_value(changed_to)        
      end

      return_text_lines << "#{display_attribute} : changed from #{display_from} to #{display_to}"
    end
    return_text_lines.join("\r\n")
  end

  def blank_or_name(id,model)
    object = Object.const_get(model)
    if(id.blank?)
      '(blank)'
    elsif(object.is_a?(Class) and item = object.find_by_id(id))
      item.name
    else
      '(unknown)'
    end
  end    

  def blank_or_value(value)
    if(value.blank?)
      '(blank)'
    else
      value
    end
  end    

end