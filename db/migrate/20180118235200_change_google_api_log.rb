class ChangeGoogleApiLog < ActiveRecord::Migration
  def change
    # clear out all current api logs
    execute "TRUNCATE `google_api_logs`"
    remove_column(:google_api_logs, :resultcode)
    remove_column(:google_api_logs, :errordata)
    rename_column(:google_api_logs, 'account_id', 'user_key')
    rename_column(:google_api_logs, 'group_id', 'group_key')
    add_column(:google_api_logs, :has_error, :boolean, null: false, default: false)
    add_column(:google_api_logs, :error_class, :string, null: true)
    add_column(:google_api_logs, :error_message, :string, null: true)
  end
end
