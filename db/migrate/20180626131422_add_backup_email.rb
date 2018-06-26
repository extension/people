class AddBackupEmail < ActiveRecord::Migration
  def change
    add_column(:people, :backup_email, :string, null: true, limit: 96)
  end
end
