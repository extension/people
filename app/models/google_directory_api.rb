# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
require 'google/api_client'

class GoogleDirectoryApi

  DIRECTORY_API = 'directory_v1'
  CACHED_DIRECTORY_API_FILE = "#{Rails.root}/config/googleapi/#{DIRECTORY_API}.cached.json"

  def initialize
    # establish the connection and get an access token
    # I don't know how long the access tokens live for
    # at the moment, so we're probably going to do this
    # insane dance every single time for now.

    @apps_connection = Google::APIClient.new(:application_name => 'eXtension People', :application_version => '2')
    signing_key = Google::APIClient::KeyUtils.load_from_pkcs12("#{Rails.root}/config/googleapi/#{Settings.googleapps_key_file}", Settings.googleapps_key_secret)
    @apps_connection.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/admin.directory.user',
      :issuer => Settings.googleapps_service_account,
      :signing_key => signing_key,
      :person => Settings.googleapps_account)
    @apps_connection.authorization.fetch_access_token!

    # load the directory API

    # Load cached discovered API, if it exists. This prevents retrieving the
    # discovery document on every run, saving a round-trip to API servers.
    if File.exists?(CACHED_DIRECTORY_API_FILE)
      File.open(CACHED_DIRECTORY_API_FILE) do |file|
        @directory_api = Marshal.load(file)
      end
    else
      @directory_api = self.apps_connection.discovered_api('admin', DIRECTORY_API)
      File.open(CACHED_DIRECTORY_API_FILE, 'w') do |file|
        Marshal.dump(@directory_api, file)
      end
    end

    self

  end

  def retrieve_account(google_account)
    api_method = lambda do
    @apps_connection.execute(
      :api_method => @directory_api.users.get,
      :parameters => {'userKey' => "#{google_account.username}@extension.org"}
    )
    end
    result = api_method.call()
    if(result.status == 200)
      result.data.to_hash
    else
      nil
    end
  end

  def create_account(google_account)
    if(!(password = google_account.person.password_reset))
      password = SecureRandom.hex(16)
    end

    # TODO: we do have the potential of associating the
    # google account back to the people ID. No idea why
    # that might be useful at the moment, but it's worth
    # mentioning.  Ton of other directory data at:
    # https://developers.google.com/admin-sdk/directory/v1/guides/manage-users#create_user

    account_data = @directory_api.users.insert.request_schema.new({
      'primaryEmail' => "#{google_account.username}@extension.org",
      "name" => {
        "givenName" => google_account.given_name,
        "familyName" => google_account.family_name
      },
      "suspended" => (google_account.suspended? ? "true" : "false"),
      "password" =>  password,
      "hashFunction" => "SHA-1"
    })

    api_method = lambda do
      @apps_connection.execute(
        :api_method => @directory_api.users.insert,
        :body_object => account_data
      )
    end

    result = api_method.call()
    if(result.status == 200)
      result.data.to_hash
    else
      nil
    end
  end


end
