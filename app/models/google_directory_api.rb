# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
require 'google/api_client'

# This is kind of a stupid class because it has domain
# knowledge of both the GoogleAccount and GoogleGroup
# models - but you know, sometimes you make it work
# and refactor it later (or never).

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
      :scope => ['https://www.googleapis.com/auth/admin.directory.user','https://www.googleapis.com/auth/admin.directory.group'],
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

  def directory_api_object
    @directory_api
  end

  def last_result
    if(!@last_result.nil?)
      @last_result.data.to_hash
    else
      nil
    end
  end

  def last_raw_result
    @last_result
  end

  def retrieve_account(google_account)
    @last_result = @apps_connection.execute(
      :api_method => @directory_api.users.get,
      :parameters => {'userKey' => "#{google_account.username}@extension.org"}
    )
    return (@last_result.status == 200)
  end

  def create_account(google_account)
    if(!(password = google_account.person.password_reset))
      password = SecureRandom.hex(16)
    end

    create_parameters = {
      'primaryEmail' => "#{google_account.username}@extension.org",
      "name" => {
        "givenName" => google_account.given_name,
        "familyName" => google_account.family_name
      },
      "suspended" => (google_account.suspended? ? "true" : "false"),
      "password" =>  password,
      "hashFunction" => "SHA-1"
    }

    account_data = @directory_api.users.insert.request_schema.new(create_parameters)

    @last_result = @apps_connection.execute(
      :api_method => @directory_api.users.insert,
      :body_object => account_data
    )
    return (@last_result.status == 200)
  end

  def update_account(google_account)
    if(!(password = google_account.person.password_reset))
      password = SecureRandom.hex(16)
    end

    update_parameters = {
      'primaryEmail' => "#{google_account.username}@extension.org",
      "name" => {
        "givenName" => google_account.given_name,
        "familyName" => google_account.family_name
      },
      "suspended" => (google_account.suspended? ? "true" : "false"),
    }

    if(password = google_account.person.password_reset)
      update_parameters["password"] = password
      update_parameters["hashFunction"] = "SHA-1"
    end

    account_data = @directory_api.users.update.request_schema.new(update_parameters)

    @last_result = @apps_connection.execute(
      :api_method => @directory_api.users.update,
      :parameters => {'userKey' => "#{google_account.username}@extension.org"},
      :body_object => account_data
    )
    return (@last_result.status == 200)
  end


  def retrieve_group(group_idstring)
    @last_result = @apps_connection.execute(
      :api_method => @directory_api.groups.get,
      :parameters => {'groupKey' => "#{group_idstring}@extension.org"}
    )
    return (@last_result.status == 200)
  end

  def create_group(group_idstring, create_options = {})
    create_parameters = {
      'email' => "#{group_idstring}@extension.org",
      "description" => create_options[:description],
      "name" => create_options[:name]
    }

    group_data = @directory_api.groups.insert.request_schema.new(create_parameters)

    @last_result = @apps_connection.execute(
      :api_method => @directory_api.groups.insert,
      :body_object => group_data
    )
    return (@last_result.status == 200)
  end

  def update_group(group_idstring, update_options = {})
    update_parameters = {
      'email' => "#{group_idstring}@extension.org",
      "description" => update_options[:description],
      "name" => update_options[:name]
    }

    group_data = @directory_api.groups.update.request_schema.new(update_parameters)

    api_method = lambda do
      @apps_connection.execute(
        :api_method => @directory_api.groups.update,
        :body_object => group_data
      )
    end

    @last_result = api_method.call()
    return (@last_result.status == 200)
  end





end
