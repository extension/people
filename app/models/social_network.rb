# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class SocialNetwork < ActiveRecord::Base
  ## includes

  ## attributes
  attr_accessible :name, :display_name, :url_format, :url_format_notice, :editable_url, :autocomplete, :active

  ## constants
  OTHER_NETWORK = 1

  ## validations

  ## filters

  ## associations
  has_many :social_network_connections
  has_many :people, through: :social_network_connections

  ## scopes

  scope :active, where(active: true)

  def is_other?
    (self.id == OTHER_NETWORK)
  end

end