# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
require 'google/apis/groupssettings_v1'

class GoogleGroupSettingsApi

  def initialize
    # establish the connection and get an access token
    # I don't know how long the access tokens live for
    # at the moment, so we're probably going to do this
    # insane dance every single time for now.

    @service = Google::Apis::GroupssettingsV1::GroupssettingsService.new
    @service.client_options.application_name = 'eXtension People'
    @google_api_auth = GoogleApiAuth.new
    @service.authorization = @google_api_auth.authorizer
    self
  end

  def service
    @service
  end

  def api_log
    @api_log
  end


  def retrieve_group(group_key)
    api_method = 'groupsettings.get_group'
    begin
      google_group = @service.get_group(group_key)
      @api_log = GoogleApiLog.log_success_request(api_method: api_method,
                                                  group_key: group_key)
      return google_group
    rescue StandardError => e
      @api_log = GoogleApiLog.log_error_request(api_method: api_method,
                                                group_key: group_key,
                                                error_class: e.class.to_s,
                                                error_message: e.message)
      return nil
    end
  end

end
