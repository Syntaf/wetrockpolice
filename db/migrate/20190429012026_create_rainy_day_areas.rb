class CreateRainyDayAreas < ActiveRecord::Migration[5.1]
  def change
    create_table :rainy_day_areas do |t|
      t.references :climbing_area, foreign_key: true
      t.references :watched_area, foreign_key: true

      t.timestamps
    end
  end
end
