class AddTermsFlag < ActiveRecord::Migration
  def change
    add_column(:people,'tou_status',:integer, :null => false, :default => Person::TOU_NOT_PRESENTED)
    add_column(:people,'tou_status_date',:datetime)
  end
end
