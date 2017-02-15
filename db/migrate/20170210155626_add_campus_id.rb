class AddCampusId < ActiveRecord::Migration
  def change
    add_column(:people, :campus_id, :integer, null: true)
  end
end
