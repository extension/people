class PosterChanges < ActiveRecord::Migration
  def change
    add_column(:people, :avatar, :string)
    add_column(:communities, :is_public, :boolean, :default => false)
  end

end
