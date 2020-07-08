class CreateShirtOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :shirt_orders do |t|
      t.string :shirt_type, null: false
      t.string :shirt_size, null: false
      t.string :shirt_color, null: false
      t.references :joint_membership_application, foreign_key: true

      t.timestamps
    end

    remove_column :joint_membership_applications, :local_shirt
    remove_column :joint_membership_applications, :access_fund_shirt
    remove_column :joint_membership_applications, :shirt_size
    remove_column :joint_membership_applications, :shirt_color
  end
end
