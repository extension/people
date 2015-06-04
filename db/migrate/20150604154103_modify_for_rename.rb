class ModifyForRename < ActiveRecord::Migration
  def change
    add_column(:account_syncs, 'is_rename', :boolean, default: false)
  end
end
