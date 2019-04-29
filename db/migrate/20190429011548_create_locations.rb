class CreateLocations < ActiveRecord::Migration[5.1]
  def change
    create_table :locations do |t|
      t.string :longitude
      t.string :latitude
      t.string :mt_z
      t.references :climbing_area, foreign_key: true

      t.timestamps
    end
  end
end
