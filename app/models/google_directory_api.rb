# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
require 'google/apis/admin_directory_v1'

class GoogleDirectoryApi



  def initialize
    # establish the connection and get an access token
    # I don't know how long the access tokens live for
    # at the moment, so we're probably going to do this
    # insane dance every single time for now.

    @service = Google::Apis::AdminDirectoryV1::DirectoryService.new
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

  def retrieve_account(account_idstring)
    user_key = "#{account_idstring}@extension.org"

    api_method = 'get_user'
    begin
      google_account = @service.get_user(user_key)
      @api_log = GoogleApiLog.log_success_request(api_method: api_method,
                                                  user_key: user_key)
      return google_account
    rescue StandardError => e
      @api_log = GoogleApiLog.log_error_request(api_method: api_method,
                                                user_key: user_key,
                                                error_class: e.class.to_s,
                                                error_message: e.message)
      return nil
    end
  end

  def create_account(account_idstring,account_options)
    user_key = "#{account_idstring}@extension.org"
    if(!(password = account_options[:password]))
      password = SecureRandom.hex(16)
    end

    user_object = Google::Apis::AdminDirectoryV1::User.new
    user_object.primary_email = user_key
    user_object.name = Google::Apis::AdminDirectoryV1::UserName.new
    user_object.name.given_name = account_options[:given_name]
    user_object.name.family_name = account_options[:family_name]
    user_object.password = password
    user_object.suspended = account_options[:suspended] ? "true" : "false"
    user_object.hash_function = "SHA-1"


    api_method = 'insert_user'

    begin
      google_account = @service.insert_user(user_object)
      @api_log = GoogleApiLog.log_success_request(api_method: api_method,
                                                  user_key: user_key)
      return google_account
    rescue StandardError => e
      @api_log = GoogleApiLog.log_error_request(api_method: api_method,
                                                user_key: user_key,
                                                error_class: e.class.to_s,
                                                error_message: e.message)
      return nil
    end
  end

  def update_account(account_idstring,account_options)
    user_key = "#{account_idstring}@extension.org"


    user_object = Google::Apis::AdminDirectoryV1::User.new
    user_object.primary_email = user_key
    user_object.name = Google::Apis::AdminDirectoryV1::UserName.new
    user_object.name.given_name = account_options[:given_name]
    user_object.name.family_name = account_options[:family_name]
    user_object.suspended = account_options[:suspended] ? "true" : "false"

    if(password = account_options[:password])
      if(password == 'random')
        password = SecureRandom.hex(16)
      end
      user_object.password = password
      user_object.hash_function = "SHA-1"
    end

    api_method = 'update_user'

    begin
      google_account = @service.update_user(user_key,user_object)
      @api_log = GoogleApiLog.log_success_request(api_method: api_method,
                                                  user_key: user_key)
      return google_account
    rescue StandardError => e
      @api_log = GoogleApiLog.log_error_request(api_method: api_method,
                                                user_key: user_key,
                                                error_class: e.class.to_s,
                                                error_message: e.message)
      return nil
    end
  end


  #
  #
  # def retrieve_group(group_key)
  #   @last_result = self.api_request({
  #     :api_method => @directory_api.groups.get,
  #     :parameters => {'groupKey' => "#{group_key}"}
  #   },{group_id: group_key}
  #   )
  #   return (@last_result.status == 200)
  # end
  #
  # def create_group(group_key, create_options = {})
  #   create_parameters = {
  #     'email' => "#{group_key}",
  #     "description" => create_options[:description],
  #     "name" => create_options[:name]
  #   }
  #
  #   group_data = @directory_api.groups.insert.request_schema.new(create_parameters)
  #
  #   @last_result = self.api_request(
  #     {:api_method => @directory_api.groups.insert,
  #       :body_object => group_data},
  #     {group_id: group_key}
  #   )
  #   return (@last_result.status == 200)
  # end
  #
  # def update_group(group_key, update_options = {})
  #   update_parameters = {
  #     'email' => "#{group_key}",
  #     "description" => update_options[:description],
  #     "name" => update_options[:name]
  #   }
  #
  #   group_data = @directory_api.groups.update.request_schema.new(update_parameters)
  #
  #   @last_result = self.api_request(
  #     {:api_method => @directory_api.groups.update,
  #      :parameters => {'groupKey' => "#{group_key}"},
  #      :body_object => group_data},
  #     {group_id: group_key}
  #   )
  #   return (@last_result.status == 200)
  # end
  #
  # def retrieve_group_members(group_key)
  #   if(!self.retrieve_group(group_key))
  #     return nil
  #   end
  #
  #   request_parameters = {'groupKey' => "#{group_key}"}
  #
  #   # group membership requests are limited to 200 members
  #   # so like Pokémon, we gotta catch them all
  #   did_we_catch_them_all = false
  #   pagination_token = nil
  #   member_email_addresses = []
  #   while(!did_we_catch_them_all)
  #     if(!pagination_token.nil?)
  #       request_parameters['pageToken'] = pagination_token
  #     else
  #       request_parameters['pageToken'] = nil
  #     end
  #
  #     @last_result =  self.api_request(
  #       {:api_method => @directory_api.members.list,
  #       :parameters => request_parameters},
  #       {group_id: group_key}
  #     )
  #     last_result_data = @last_result.data.to_hash
  #
  #     if(last_result_data['nextPageToken'])
  #       pagination_token = last_result_data['nextPageToken']
  #       did_we_catch_them_all = false
  #     else
  #       did_we_catch_them_all = true
  #       pagination_token = nil
  #     end
  #
  #
  #     if(@last_result.status == 200)
  #       members = last_result_data['members']
  #       if(!members.nil?)
  #         members.each do |member_resource|
  #           if(!member_resource['email'].blank?)
  #             member_email_addresses << member_resource['email']
  #           end
  #         end
  #       end
  #     else
  #       # yes potentially breaking out of the loop
  #       # but if the request fails, I want to get
  #       # that error
  #       return nil
  #     end
  #   end
  #
  #   member_email_addresses
  # end
  #
  # def add_member_to_group(email_address,group_key)
  #   add_parameters = {
  #     'email' => email_address
  #   }
  #
  #   # hardcoded role of member or owner depending
  #   # on whether this is the moderator account
  #
  #   if(email_address == 'systemsmoderator@extension.org')
  #     add_parameters['role'] = 'OWNER'
  #   else
  #     add_parameters['role'] = 'MEMBER'
  #   end
  #
  #   member_data = @directory_api.members.insert.request_schema.new(add_parameters)
  #
  #   @last_result = self.api_request(
  #     {:api_method => @directory_api.members.insert,
  #     :parameters => {'groupKey' => "#{group_key}"},
  #     :body_object => member_data},
  #     {group_id: group_key, account_id: email_address}
  #   )
  #   return (@last_result.status == 200)
  #
  # end
  #
  #
  # def remove_member_from_group(email_address,group_key)
  #   @last_result = self.api_request(
  #     {:api_method => @directory_api.members.delete,
  #     :parameters => {'memberKey' => email_address,
  #                     'groupKey' => "#{group_key}"}},
  #                     {group_id: group_key, account_id: email_address}
  #   )
  #   return (@last_result.status == 204)
  # end
  #
  #
  #



end
