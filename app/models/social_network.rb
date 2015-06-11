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

  scope :active, -> {where(active: true)}

  scope :with_connection_attributes, -> {joins(:social_network_connections)
                                         .select("DISTINCT(social_networks.id),
                                         social_networks.*,
                                         social_network_connections.id as connection_id,
                                         social_network_connections.custom_network_name as custom_network_name,
                                         social_network_connections.accountid as accountid,
                                         social_network_connections.accounturl as accounturl,
                                         social_network_connections.is_public as is_public" )}


  def is_other?
    (self.id == OTHER_NETWORK)
  end

end
