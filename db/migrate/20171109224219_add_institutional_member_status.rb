class AddInstitutionalMemberStatus < ActiveRecord::Migration
  def change
    add_column(:communities, :membership_level, :integer, null: false, default: Community::NOT_MEMBER)
  end
end
