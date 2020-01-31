class AddOrderIdToMembershipApps < ActiveRecord::Migration[5.2]
  def change
    add_column :joint_membership_applications, :order_id, :string
  end
end
