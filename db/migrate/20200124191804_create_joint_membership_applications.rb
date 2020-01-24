class CreateJointMembershipApplications < ActiveRecord::Migration[5.2]
  def change
    create_table :joint_membership_applications do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone_number

      t.string :street_line_one
      t.string :street_line_two
      t.string :city
      t.string :state
      t.string :zipcode
      
      t.string :organization
      t.string :amount_paid

      t.string :shirt_size
      t.string :shirt_type

      t.timestamps
    end
  end
end
