class AddShirtColorToApplication < ActiveRecord::Migration[6.0]
  def change
    add_column :joint_membership_applications, :shirt_color, :string, null: true
  end
end
