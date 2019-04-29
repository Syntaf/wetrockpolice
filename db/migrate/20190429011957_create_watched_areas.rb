class CreateWatchedAreas < ActiveRecord::Migration[5.1]
  def change
    create_table :watched_areas do |t|
      t.string :name

      t.timestamps
    end
  end
end
