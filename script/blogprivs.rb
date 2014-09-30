#!/usr/bin/env ruby

require 'rubygems'
require 'atom'
require 'net/http'
require 'uri'
require 'cgi'
require 'mysql2'
require 'thor'
require 'fastercsv'

class Blogprivs < Thor

  @@MYSQL_USER = ""
  @@MYSQL_SECRET = ""
  @@MYSQL_HOST = ""
  @@MYSQL_PORT = 3306

  @@WP_DB = ""
  @@PEOPLE_DB = ""
  @@PEOPLE_USER = ""
  @@PEOPLE_SECRET = ""

  #@@WP_DB_CONNECTION = Mysql.real_connect(@@MYSQL_HOST, @@MYSQL_USER, @@MYSQL_SECRET, @@WP_DB, @@MYSQL_PORT)
  @@WP_DB_CONNECTION = Mysql2::Client.new(:host => @@MYSQL_HOST, :port => @@MYSQL_PORT, :database => @@WP_DB, :username => @@MYSQL_USER, :password => @@MYSQL_SECRET)
  @@PEOPLE_DB_CONNECTION = Mysql2::Client.new(:host => @@MYSQL_HOST, :port => @@MYSQL_PORT, :database => @@PEOPLE_DB, :username => @@PEOPLE_USER, :password => @@PEOPLE_SECRET)

  @@DEFAULT_USER_PASS = ""


  @@WP_ADMIN_PRIVS = "a:1:{s:13:\"administrator\";s:1:\"1\";}"
  @@WP_EDITOR_PRIVS = "a:1:{s:6:\"editor\";s:1:\"1\";}"

  @@GET_WP_USER_ID = "SELECT ID from `#{@@WP_DB}`.wp_users WHERE user_login ="
  @@SET_ADMIN_PRIVS="INSERT INTO `#{@@WP_DB}`.wp_usermeta (`umeta_id`,`user_id`,`meta_key`,`meta_value`) "
  @@SET_EDITOR_PRIVS="INSERT INTO `#{@@WP_DB}`.wp_usermeta (`umeta_id`,`user_id`,`meta_key`,`meta_value`) "
  @@SET_RICH_EDITING = "INSERT INTO `#{@@WP_DB}`.wp_usermeta (`umeta_id`,`user_id`,`meta_key`,`meta_value`) "

  @@ADD_WP_USER = "INSERT INTO `#{@@WP_DB}`.wp_users (`id`,`user_login`,`user_pass`,`user_nicename`,`user_email`,`display_name`) "
  @@ADD_WP_OPENID_IDENTITY = "INSERT INTO `#{@@WP_DB}`.wp_openid_identities (`uurl_id`,`user_id`,`url`) "

  @@GET_PEOPLE_USER_INFO = "SELECT id,first_name,last_name,email FROM `#{@@PEOPLE_DB}`.people WHERE idstring ="


  no_tasks do

    def get_userid(extensionid)
      id = nil
      query = @@GET_WP_USER_ID+" '#{extensionid}'"
      query_result = @@WP_DB_CONNECTION.query(query, :as => :hash)
      id = query_result.first['ID']
      if !id.nil?
        return id
      end
      puts "    user not found"
      return nil
    end

    def set_admin_privs(userid, blogid)
      query = @@SET_ADMIN_PRIVS + "VALUES(NULL,'#{userid}','wp_#{blogid}_capabilities','#{@@WP_ADMIN_PRIVS}')"
      query_result = @@WP_DB_CONNECTION.query(query)
    end

    def update_admin_privs(userid,blogid,umeta_id)
      query = "UPDATE  `#{@@WP_DB}`.`wp_usermeta` SET  `meta_value` =  '#{@@WP_ADMIN_PRIVS}' WHERE  `wp_usermeta`.`umeta_id` =#{umeta_id};"
      query_result = @@WP_DB_CONNECTION.query(query)
    end

    def set_editor_privs(userid, blogid)
      query = @@SET_EDITOR_PRIVS + "VALUES(NULL,'#{userid}','wp_#{blogid}_capabilities','#{@@WP_EDITOR_PRIVS}')"
      query_result = @@WP_DB_CONNECTION.query(query)
    end

    def set_rich_editing(userid)
      query = @@SET_RICH_EDITING + "VALUES(NULL,'#{userid}','rich_editing','true')"
      puts "executing rich editing query: "+query
      query_result = @@WP_DB_CONNECTION.query(query)
      puts "rich editing set"
    end

    def update_editor_privs(userid,blogid,umeta_id)
      query = "UPDATE  `#{@@WP_DB}`.`wp_usermeta` SET  `meta_value` =  '#{@@WP_EDITOR_PRIVS}' WHERE  `wp_usermeta`.`umeta_id` =#{umeta_id};"
      query_result = @@WP_DB_CONNECTION.query(query)
    end


    def has_existing_privs(userid,blogid)
      query = "select count(*),umeta_id from `#{@@WP_DB}`.wp_usermeta WHERE user_id = '#{userid}' AND meta_key = 'wp_#{blogid}_capabilities'"
      query_result = @@WP_DB_CONNECTION.query(query, :as => :hash)
      if query_result.first['count(*)'] > 0
        return query_result.first['umeta_id']
      else
        return false
      end
    end

    def insert_openid_info(id, idstring)
      query = @@ADD_WP_OPENID_IDENTITY + " VALUES(#{id},#{id},'https://people.extension.org/#{idstring}');"
      puts "executing openid insertion query: "+query
      result = @@WP_DB_CONNECTION.query(query)
      puts "openid info added"

    end

    def create_wp_user(idstring)
      people_info = @@GET_PEOPLE_USER_INFO + " '#{idstring}';"
      result = @@PEOPLE_DB_CONNECTION.query(people_info, :as => :hash)
      if result.size != 1
        puts "something went wrong. more or less than 1 row returned from the users db"
        return false
      end
      person = result.first
      fullname = person['first_name']+" "+person["last_name"]
      create_query = @@ADD_WP_USER + "VALUES( #{person['id']}, '#{idstring}', '#{@@DEFAULT_USER_PASS}', '#{fullname}', '#{person['email']}', '#{idstring}' );"
      puts "executing wp user account creation query: "+create_query
      result = @@WP_DB_CONNECTION.query(create_query)
      insert_openid_info(person['id'],idstring)
      set_rich_editing(person['id'])
    end

  end



  desc "grant_admin EXTENSIONID BLOGID", "grant admin privs to EXTENSIONID for BLOGID"
  def grant_admin(extensionid,blogid)
    puts "  looking up #{extensionid}'s userid"
    userid = get_userid(extensionid)
    if !userid.nil?
      puts "    userid found: #{userid}"
      puts "    checking for existing privs..."
      priv_check = has_existing_privs(userid,blogid)
      if priv_check == false
        puts "    setting admin privs"
        set_admin_privs(userid,blogid)
      else
        puts "    updating admin privs"
        update_admin_privs(userid,blogid,priv_check)
      end
    end
  end

  desc "grant_editor EXTENSIONID BLOGID", "grant editor privs to EXTENSIONID for BLOGID"
  def grant_editor(extensionid,blogid)
    puts "  looking up #{extensionid}'s userid"
    userid = get_userid(extensionid)
    if !userid.nil?
      puts "    userid found: #{userid}"
      puts "    checking for existing privs..."
      priv_check = has_existing_privs(userid,blogid)
      if priv_check == false
        puts "    setting editor privs"
        set_editor_privs(userid,blogid)
      else
        update_editor_privs(userid,blogid,priv_check)
      end
    end
  end

  desc "create_user IDSTRING", "create a wordpress user with IDSTRING and openidentities and rich_editng enabled"
  def create_user(idstring)
    puts "  creating new wp user account for #{idstring}"
    create_wp_user(idstring)
  end



end

Blogprivs.start
