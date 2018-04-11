class RemoveUnnecessaryGaMarking < ActiveRecord::Migration
  def change
    remove_column(:google_accounts, :marked_for_removal)
  end
end
