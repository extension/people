class SocialNetworkCleanup < ActiveRecord::Migration
  def up
    ['friendfeed','magnolia','identica','msnim','jabber','gizmo','wave'].each do |social_network_name|
      if(sn = SocialNetwork.where(name: social_network_name).first)
        sn.destroy
      end
    end
  end
end
