class AddInstitutionalMemberStatus < ActiveRecord::Migration
  def change
    add_column(:communities, :membership_status, :integer, null: false, default: Community::NOT_MEMBER)
  end
end
