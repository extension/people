class ChangeEmailForwarding < ActiveRecord::Migration
  def up
    add_column(:people, :display_extension_email, :boolean, default: false, null: false)
    Person.reset_column_information
    update_list = Person.where(primary_account_id: nil).where("email_forward IS NOT NULL").all
    update_list.each do |p|
      p.email = p.read_attribute(:email_forward)
      p.display_extension_email = true
      p.save
    end
    remove_column(:people, :email_forward)
  end

  def down
  end
end
