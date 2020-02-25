class AddPendingStatus < ActiveRecord::Migration[5.2]
  def change
    add_column :joint_membership_applications, :pending, :boolean, null: false, default: false
  end
end
