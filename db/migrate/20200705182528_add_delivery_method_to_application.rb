class AddDeliveryMethodToApplication < ActiveRecord::Migration[6.0]
  def change
    add_column :joint_membership_applications, :delivery_method, :string, null: true
  end
end
