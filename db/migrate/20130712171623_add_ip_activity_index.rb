class AddIpActivityIndex < ActiveRecord::Migration
  def change
  	add_index(:activities, 'ip_address', name: 'ip_ndx')
  end
end
