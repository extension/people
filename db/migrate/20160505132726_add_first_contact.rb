class AddFirstContact < ActiveRecord::Migration
  def change
    add_column(:communities, :primary_contact_id, :integer, default: nil, null: true)
  end
end
