# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
require 'googleauth'

class GoogleApiAuth


  API_SCOPES = ['https://www.googleapis.com/auth/admin.directory.user',
                'https://www.googleapis.com/auth/admin.directory.group',
                'https://www.googleapis.com/auth/apps.groups.settings']

  def initialize
    @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
                  json_key_io: File.open("#{Rails.root}/config/googleapi/#{Settings.googleapps_service_credentials}"),
                  scope: API_SCOPES)
    @authorizer.sub = Settings.googleapps_impersonation_account
    @authorizer.fetch_access_token!
    self
  end

  def authorizer
    @authorizer
  end

end
