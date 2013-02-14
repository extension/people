# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class SocialNetworkConnection < ActiveRecord::Base
  ## includes

  ## attributes
  attr_accessor :fieldid
  attr_accessible :person, :person_id, :social_network, :social_network_id, :network_name, :url_format, :custom_network_name, :accountid, :accounturl, :privacy, :is_public

  ## validations

  ## filters

  ## associations
  belongs_to :person
  belongs_to :social_network

  ## scopes
  scope :public, where(is_public: true)

  ## constants

end