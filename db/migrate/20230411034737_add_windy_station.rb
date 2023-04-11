class AddWindyStation < ActiveRecord::Migration[6.1]
  def change
    add_column :watched_areas, :webcam_stid, :string, null: true
  end
end
