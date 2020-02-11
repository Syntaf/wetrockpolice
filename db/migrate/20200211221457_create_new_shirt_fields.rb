class CreateNewShirtFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :joint_membership_applications, :shirt_type
    
    add_column :joint_membership_applications, :local_shirt, :boolean
    add_column :joint_membership_applications, :access_fund_shirt, :boolean
  end
end
