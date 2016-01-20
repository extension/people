class AddSystemFlag < ActiveRecord::Migration
  def change
    add_column(:people, :is_systems_account, :boolean, default: false)

    # change data
    SYSTEMS_USERS = [1,2,3,4,5,6,7,8]
    execute "UPDATE people SET is_systems_account = 1 where people.id IN (#{SYSTEMS_USERS.join(',')})"


  end
end
