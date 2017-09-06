class AddRetiredTime < ActiveRecord::Migration
  def change
    add_column(:people, :retired_at, :datetime, null: true)
  end
end
