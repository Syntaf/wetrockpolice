class SuperAdminAndManagesArray < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :super_admin, :boolean, :default => false, :null => false
    add_column :users, :manages, :text, :default => [].to_yaml, :null => false
  end

  def down
    remove_column :users, :super_admin
    remove_column :users, :manages
  end
end
