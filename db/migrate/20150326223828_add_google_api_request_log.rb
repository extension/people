class AddGoogleApiRequestLog < ActiveRecord::Migration
  def change

    create_table "google_api_logs", :force => true do |t|
      t.datetime "created_at"
      t.string   "api_method"
      t.string   "group_id"
      t.string   "account_id"
      t.integer  "resultcode"
      t.text     "errordata"
    end

  end

end
