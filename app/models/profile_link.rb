# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
require 'net/https'

class ProfileLink < ActiveRecord::Base
  serialize :last_check_information

  # check_status codes
  OK = 1
  OK_REDIRECT = 2
  WARNING = 3
  BROKEN = 4
  IGNORED = 5

  # maximum number of times a broken link reports broken before warning goes to error
  MAX_WARNING_COUNT = 3

  # maximum number of times we'll check a broken link before giving up
  MAX_ERROR_COUNT = 10

  def self.check_url(url,make_get_request=false)
    headers = {'User-Agent' => 'extension.org link verification'}
    # the URL should have likely already be validated, but let's do it again for good measure
    begin
      check_uri = URI.parse("#{url}")
    rescue Exception => exception
      return {:responded => false, :error => exception.message}
    end

    if(check_uri.scheme != 'http' and check_uri.scheme != 'https')
      return {:responded => false, :ignored => true}
    end

    # check it!
    begin
      response = nil
      http_connection = Net::HTTP.new(check_uri.host, check_uri.port)
      if(check_uri.scheme == 'https')
        # don't verify cert?
        http_connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http_connection.use_ssl = true
      end
      request_path = !check_uri.path.blank? ? check_uri.path : "/"
      if(!check_uri.query.blank?)
        request_path += "?" + check_uri.query
      end

      if(!make_get_request)
        response = http_connection.head(request_path,headers)
      else
        response = http_connection.get(request_path,headers)
      end
      {:responded => true, :code => response.code, :response => response}
    rescue Exception => exception
      return {:responded => false, :error => exception.message}
    end
  end

  def check_url(options = {})
    save = (!options[:save].nil? ? options[:save] : true)
    force_error_check = (!options[:force_error_check].nil? ? options[:force_error_check] : false)
    make_get_request = (!options[:make_get_request].nil? ? options[:make_get_request] : false)
    check_again_with_get = (!options[:check_again_with_get].nil? ? options[:check_again_with_get] : true)

    return if(!force_error_check and self.error_count >= MAX_ERROR_COUNT)

    self.last_check_at = Time.zone.now
    result = self.class.check_url(self.url,make_get_request)
    # make get request if responded, and response code was '404' and we didn't initially make a get request
    if(result[:responded] and !make_get_request and check_again_with_get and (result[:code] =='404' or result[:code] =='405' or result[:code] =='403'))
      result = self.class.check_url(self.url,true)
    end

    if(result[:responded])
      self.last_check_response = true
      self.last_check_information = {:response_headers => result[:response].to_hash}
      self.last_check_code = result[:code]
      if(result[:code] == '200')
        self.check_status = OK
        self.last_check_status = OK
        self.error_count = 0
      elsif(result[:code] == '301' or result[:code] == '302' or result[:code] == '303' or result[:code] == '307')
        self.check_status = OK_REDIRECT
        self.last_check_status = OK_REDIRECT
        self.error_count = 0
      else
        self.error_count += 1
        if(self.error_count >= MAX_WARNING_COUNT)
          self.check_status = BROKEN
        else
          self.check_status = WARNING
        end
        self.last_check_status = BROKEN
      end
    elsif(result[:ignored])
      self.last_check_response = false
      self.check_status = IGNORED
      self.last_check_status = IGNORED
    else
      self.last_check_response = false
      self.last_check_information = {:error => result[:error]}
      self.error_count += 1
      if(self.error_count >= MAX_WARNING_COUNT)
        self.check_status = BROKEN
      else
        self.check_status = WARNING
      end
      self.last_check_status = BROKEN
    end
    self.save
    return result
  end

end
