class AddCoordinatesToWatchedArea < ActiveRecord::Migration[6.0]
  def change
    add_column :watched_areas, :longitude, :string, null: false, default: '0'
    add_column :watched_areas, :latitude, :string, null: false, default: '0'
  end
end
