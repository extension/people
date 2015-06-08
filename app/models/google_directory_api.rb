# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
require 'google/api_client'

class GoogleDirectoryApi

  DIRECTORY_API = 'directory_v1'
  CACHED_DIRECTORY_API_FILE = "#{Rails.root}/tmp/cache/#{DIRECTORY_API}.cached.json"

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
      @directory_api = @apps_connection.discovered_api('admin', DIRECTORY_API)
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

  def retrieve_account(account_idstring)
    @last_result = self.api_request(
      {:api_method => @directory_api.users.get,
      :parameters => {'userKey' => "#{account_idstring}@extension.org"}},
      {account_id: account_idstring}
    )
    return (@last_result.status == 200)
  end

  def create_account(account_idstring,account_options)
    if(!(password = account_options[:password]))
      password = SecureRandom.hex(16)
    end

    create_parameters = {
      'primaryEmail' => "#{account_idstring}@extension.org",
      "name" => {
        "givenName" => account_options[:given_name],
        "familyName" => account_options[:family_name]
      },
      "suspended" => (account_options[:suspended] ? "true" : "false"),
      "password" =>  password,
      "hashFunction" => "SHA-1"
    }

    account_data = @directory_api.users.insert.request_schema.new(create_parameters)

    @last_result =  self.api_request(
      {:api_method => @directory_api.users.insert,
      :body_object => account_data},
      {account_id: account_idstring}
    )
    return (@last_result.status == 200)
  end

  def update_account(user_key,account_idstring, account_options)

    update_parameters = {
      'primaryEmail' => "#{account_idstring}@extension.org",
      "name" => {
        "givenName" => account_options[:given_name],
        "familyName" => account_options[:family_name]
      },
      "suspended" => (account_options[:suspended] ? "true" : "false"),
    }

    if(password = account_options[:password])
      update_parameters["password"] = password
      update_parameters["hashFunction"] = "SHA-1"
    end

    account_data = @directory_api.users.update.request_schema.new(update_parameters)

    @last_result = self.api_request(
      {:api_method => @directory_api.users.update,
      :parameters => {'userKey' => user_key},
      :body_object => account_data},
      {account_id: account_idstring}
    )
    return (@last_result.status == 200)
  end


  def retrieve_group(group_idstring)
    @last_result = self.api_request({
      :api_method => @directory_api.groups.get,
      :parameters => {'groupKey' => "#{group_idstring}@extension.org"}
    },{group_id: group_idstring}
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

    @last_result = self.api_request(
      {:api_method => @directory_api.groups.insert,
        :body_object => group_data},
      {group_id: group_idstring}
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

    @last_result = self.api_request(
      {:api_method => @directory_api.groups.update,
       :parameters => {'groupKey' => "#{group_idstring}@extension.org"},
       :body_object => group_data},
      {group_id: group_idstring}
    )
    return (@last_result.status == 200)
  end

  def retrieve_group_members(group_idstring)
    if(!self.retrieve_group(group_idstring))
      return nil
    end

    request_parameters = {'groupKey' => "#{group_idstring}@extension.org"}

    # group membership requests are limited to 200 members
    # so like Pokémon, we gotta catch them all
    did_we_catch_them_all = false
    pagination_token = nil
    returnmembers = []
    while(!did_we_catch_them_all)
      if(!pagination_token.nil?)
        request_parameters['pageToken'] = pagination_token
      else
        request_parameters['pageToken'] = nil
      end

      @last_result =  self.api_request(
        {:api_method => @directory_api.members.list,
        :parameters => request_parameters},
        {group_id: group_idstring}
      )
      last_result_data = @last_result.data.to_hash

      if(last_result_data['nextPageToken'])
        pagination_token = last_result_data['nextPageToken']
        did_we_catch_them_all = false
      else
        did_we_catch_them_all = true
        pagination_token = nil
      end


      if(@last_result.status == 200)
        members = last_result_data['members']
        if(!members.nil?)
          members.each do |member_resource|
            if(%r{([\w-]+)\@extension\.org$} =~ member_resource['email'])
              returnmembers << $1
            end
          end
        end
      else
        # yes potentially breaking out of the loop
        # but if the request fails, I want to get
        # that error
        return nil
      end
    end

    returnmembers
  end

  def add_member_to_group(account_idstring,group_idstring)
    add_parameters = {
      'email' => "#{account_idstring}@extension.org"
    }

    # hardcoded role of member or owner depending
    # on whether this is the moderator account

    if(account_idstring == 'systemsmoderator')
      add_parameters['role'] = 'OWNER'
    else
      add_parameters['role'] = 'MEMBER'
    end

    member_data = @directory_api.members.insert.request_schema.new(add_parameters)

    @last_result = self.api_request(
      {:api_method => @directory_api.members.insert,
      :parameters => {'groupKey' => "#{group_idstring}@extension.org"},
      :body_object => member_data},
      {group_id: group_idstring, account_id: account_idstring}
    )
    return (@last_result.status == 200)

  end


  def remove_member_from_group(account_idstring,group_idstring)
    @last_result = self.api_request(
      {:api_method => @directory_api.members.delete,
      :parameters => {'memberKey' => "#{account_idstring}@extension.org",
                      'groupKey' => "#{group_idstring}@extension.org"}},
                      {group_id: group_idstring, account_id: account_idstring}
    )
    return (@last_result.status == 204)
  end



  def api_request(api_data, log_options)
    result = @apps_connection.execute(api_data)
    request_options = {}
    api_method_string = api_data[:api_method].id
    request_options[:api_method] = api_method_string
    request_options[:resultcode] = result.status
    if(api_method_string == 'directory.members.delete')
      success_status = 204
    else
      success_status = 200
    end
    if(result.status != success_status)
      request_options[:errordata] = result.data.to_hash if result.data
    end
    request_options.merge!(log_options)
    GoogleApiLog.log_request(request_options)
    result
  end

end
