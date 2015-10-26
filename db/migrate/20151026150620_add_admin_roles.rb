class AddAdminRoles < ActiveRecord::Migration
  def change
    create_table "admin_roles", :force => true do |t|
      t.integer "person_id"
      t.string  "applabel"
      t.datetime "created_at"
    end

    add_index "admin_roles", ["person_id", "applabel"], :name => 'admin_ndx', :unique => true

    AdminRole.reset_column_information

    Person.where('admin_flags NOT RLIKE "^\-\-\- \n\.\.\."').each do |p|
      p.admin_flags.each do |applabel, is_admin|
        if(is_admin)
          AdminRole.create(person_id: p.id, applabel: applabel)
        end
      end
    end

    # change labels
    execute("UPDATE admin_roles SET applabel = 'articles' where applabel = 'www'")
    execute("UPDATE admin_roles SET applabel = 'homepage' where applabel = 'about'")

    remove_column('people','admin_flags')

  end

end
