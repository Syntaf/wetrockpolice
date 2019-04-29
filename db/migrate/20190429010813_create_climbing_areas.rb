class CreateClimbingAreas < ActiveRecord::Migration[5.1]
  def change
    create_table :climbing_areas do |t|
      t.string :name
      t.string :rock_type
      t.string :description

      t.timestamps
    end
  end
end
