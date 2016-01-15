class PosterChanges < ActiveRecord::Migration
  def change
    add_column(:people, :avatar, :string)
    add_column(:communities, :community_masthead, :string)
  end

end
