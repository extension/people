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

    api_method = 'directory.get_user'
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


    api_method = 'directory.insert_user'

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

    api_method = 'directory.update_user'

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

  def delete_account(account_idstring)
    api_method = 'directory.delete_user'
    begin
      @service.delete_user(account_idstring)
      @api_log = GoogleApiLog.log_success_request(api_method: api_method,
                                                  user_key: user_key)
      return true
    rescue StandardError => e
      @api_log = GoogleApiLog.log_error_request(api_method: api_method,
                                                user_key: user_key,
                                                error_class: e.class.to_s,
                                                error_message: e.message)
      return false
    end
  end


  def retrieve_group(group_key)
    api_method = 'directory.get_group'
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


  def delete_group(group_key)
    api_method = 'directory.delete_group'
    begin
      @service.delete_group(group_key)
      @api_log = GoogleApiLog.log_success_request(api_method: api_method,
                                                  group_key: group_key)
      return true
    rescue StandardError => e
      @api_log = GoogleApiLog.log_error_request(api_method: api_method,
                                                group_key: group_key,
                                                error_class: e.class.to_s,
                                                error_message: e.message)
      return false
    end
  end

  def create_group(group_key,create_options)
    group_object = Google::Apis::AdminDirectoryV1::Group.new
    group_object.email = group_key
    group_object.name = create_options[:name]
    group_object.description = create_options[:description]

    api_method = 'directory.insert_group'

    begin
      google_group = @service.insert_group(group_object)
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


  def update_group(group_key,update_options)
    group_object = Google::Apis::AdminDirectoryV1::Group.new
    group_object.email = group_key
    group_object.name = update_options[:name]
    group_object.description = update_options[:description]

    api_method = 'directory.update_group'

    begin
      google_group = @service.update_group(group_key,group_object)
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


  def retrieve_group_members(group_key)
    if(!(google_group = self.retrieve_group(group_key)))
      return nil
    end

    # group membership requests are limited to 200 members
    # so like Pokémon, we gotta catch them all
    did_we_catch_them_all = false
    pagination_token = nil
    member_email_addresses = []
    while(!did_we_catch_them_all)
      api_method = 'directory.list_members'

      begin
        group_members = @service.list_members(group_key,{page_token: pagination_token})
        @api_log = GoogleApiLog.log_success_request(api_method: api_method,
                                                    group_key: group_key)
      rescue StandardError => e
        @api_log = GoogleApiLog.log_error_request(api_method: api_method,
                                                  group_key: group_key,
                                                  error_class: e.class.to_s,
                                                  error_message: e.message)
        return nil
      end


      if(group_members.next_page_token.nil?)
        did_we_catch_them_all = true
      else
        did_we_catch_them_all = false
        pagination_token = group_members.next_page_token
      end

      if(!group_members.members.blank?)
        group_members.members.each do |member_object|
          member_email_addresses << member_object.email.downcase
        end
      end
    end # caught them all!

    member_email_addresses
  end


  def add_member_to_group(email_address,group_key,is_owner)
    api_method = 'directory.insert_member'

    member_object = Google::Apis::AdminDirectoryV1::Member.new
    member_object.email = email_address.downcase

    if(is_owner)
      member_object.role = 'OWNER'
    else
      member_object.role = 'MEMBER'
    end

    begin
      added_member = @service.insert_member(group_key,member_object)
      @api_log = GoogleApiLog.log_success_request(api_method: api_method,
                                                  group_key: group_key,
                                                  user_key: email_address)
      return added_member
    rescue StandardError => e
      @api_log = GoogleApiLog.log_error_request(api_method: api_method,
                                                group_key: group_key,
                                                user_key: email_address,
                                                error_class: e.class.to_s,
                                                error_message: e.message)
      return nil
    end
  end

  def remove_member_from_group(email_address,group_key)
    api_method = 'directory.delete_member'
    begin
      @service.delete_member(group_key,email_address)
      @api_log = GoogleApiLog.log_success_request(api_method: api_method,
                                                  group_key: group_key,
                                                  user_key: email_address)
      return true
    rescue StandardError => e
      @api_log = GoogleApiLog.log_error_request(api_method: api_method,
                                                group_key: group_key,
                                                user_key: email_address,
                                                error_class: e.class.to_s,
                                                error_message: e.message)
      return false
    end
  end



end
