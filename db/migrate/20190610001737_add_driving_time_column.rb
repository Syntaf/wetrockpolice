class AddDrivingTimeColumn < ActiveRecord::Migration[5.1]
  def self.up
    add_column :rainy_day_areas, :driving_time, :integer
  end

  def self.down
    remove_columns :rainy_day_areas, :driving_time
  end
end
