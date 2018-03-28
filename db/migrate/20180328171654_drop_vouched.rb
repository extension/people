class DropVouched < ActiveRecord::Migration
  def up
    remove_column(:people, :vouched)
  end
end
