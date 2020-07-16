class AddDeliveredToMembership < ActiveRecord::Migration[6.0]
  def change
    add_column :joint_membership_applications, :delivered, :boolean, default: false
  end
end
