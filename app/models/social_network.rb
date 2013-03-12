# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class SocialNetwork < ActiveRecord::Base
  ## includes

  ## attributes
  attr_accessible :name, :display_name, :url_format, :url_format_notice, :editable_url, :autocomplete, :active

  ## validations

  ## filters

  ## associations
  has_many :social_network_connections
  has_many :people, through: :social_network_connections

  ## scopes

  ## constants
end