class AddBlogsCommunities < ActiveRecord::Migration
  def change
    add_column(:communities, :blog_id, :integer, default: nil, null: true)
  end
end
