class AddSlackBot < ActiveRecord::Migration
  def change
    create_table :slack_bots do |t|
      t.integer    "person_id", :default => 1
      t.string     "slack_channel_id"
      t.string     "slack_channel_name"
      t.string     "slack_user_id"
      t.string     "slack_user_name"
      t.string     "command"
      t.text       "commandtext"
      t.datetime   "created_at"
    end

    add_column(:people, :slack_user_id, :string)
  end
end
