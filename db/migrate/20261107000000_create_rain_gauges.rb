# frozen_string_literal: true

# Extra rain gauges a watched area can switch between (e.g. Red Rock's
# primary Synoptic station plus SNCC's Black Velvet gauge on CampbellCloud).
# The watched area's own `station` stays the primary gauge; these rows are
# the alternates offered by the clickable hero title.
class CreateRainGauges < ActiveRecord::Migration[8.1]
  def change
    create_table :rain_gauges do |t|
      t.references :watched_area, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :provider, null: false, default: 'synoptic'
      # Synoptic STID, or the CampbellCloud station UUID
      t.string :station, null: false
      # CampbellCloud only: which datalogger table/field holds per-interval rain
      t.string :campbell_table
      t.string :campbell_field
      # Units the provider reports rain in; normalized to inches for the chart
      t.string :units, null: false, default: 'in'
      t.text :info_bubble_excerpt, null: false, default: ''
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :rain_gauges, %i[watched_area_id slug], unique: true
  end
end
