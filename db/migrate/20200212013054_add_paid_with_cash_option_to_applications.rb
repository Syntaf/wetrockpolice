class AddPaidWithCashOptionToApplications < ActiveRecord::Migration[5.2]
  def change
    add_column :joint_membership_applications, :paid_cash, :boolean, null: false, default: false
  end
end
