class AddCoverFeeToMemberships < ActiveRecord::Migration[6.0]
  def change
    add_column :joint_membership_applications, :cover_fee, :boolean, default: false
  end
end
