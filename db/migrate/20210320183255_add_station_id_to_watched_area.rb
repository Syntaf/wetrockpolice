class AddStationIdToWatchedArea < ActiveRecord::Migration[6.0]
  def change
    add_column :watched_areas, :station, :string, null: true, default: ''
  end
end
