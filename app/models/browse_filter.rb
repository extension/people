# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class BrowseFilter < ActiveRecord::Base
  serialize :settings
  attr_accessible :creator, :created_by, :settings

  KNOWN_KEYS = ['communities','locations','positions','social_networks']

  validates :settings, :presence => true


  before_save :set_fingerprint

  belongs_to :creator, :class_name => "Person", :foreign_key => "created_by"

  def self.find_or_create_by_settings(settings,creator)
    settings_array = self.convert_settings_hash(settings)
    return nil if settings_array.blank?
    find_fingerprint = self.settings_fingerprint(settings_array)
    if(!(browse_filter = self.find_by_fingerprint(find_fingerprint)))
      browse_filter = self.create(settings: settings, creator: creator)
    end
    browse_filter
  end

  def settings
    Hash[read_attribute(:settings)]
  end

  def settings_to_objects
    objecthash = {}
    self.settings.each do |filter_key,id_list|
      case filter_key
      when 'communities'
        objecthash[filter_key] = Community.where("id in (#{id_list.join(',')})").order(:name).all
      when 'locations'
        objecthash[filter_key] = Location.where("id in (#{id_list.join(',')})").order(:name).all
      when 'positions'
         objecthash[filter_key] = Position.where("id in (#{id_list.join(',')})").order(:name).all    
      when 'social_networks'
        objecthash[filter_key] = SocialNetwork.active.where("id in (#{id_list.join(',')})").order(:display_name).all
      end        
    end
    objecthash
  end

  # settings_hash is expected to be what comes from the form POST
  # e.g. a hash of key => comma delimited string of id's
  def settings=(settings_hash)
    savesettings = self.class.convert_settings_hash(settings_hash)
    if(savesettings)
      write_attribute(:settings, savesettings)
    end
  end

  def self.convert_settings_hash(settings_hash)
    savesettings = []
    KNOWN_KEYS.each do |key|
      if(!settings_hash[key].blank?)
        savesettings << [key,settings_hash[key].split(',').map{|i| i.strip.to_i}.sort]
      end
    end
    savesettings
  end

  def self.settings_fingerprint(settings)
    Digest::SHA1.hexdigest(settings.to_yaml)
  end

  def set_fingerprint
    self.fingerprint = self.class.settings_fingerprint(read_attribute(:settings))
  end


end