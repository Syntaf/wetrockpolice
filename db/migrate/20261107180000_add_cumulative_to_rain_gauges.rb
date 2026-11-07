# frozen_string_literal: true

# A CampbellCloud gauge can be read from a running-total field (e.g.
# Rain_30min.cum_ppt_in) instead of a per-interval one. The service then
# derives each interval from the change in the total, so rain that fell while
# readings failed to upload still shows up, credited to the first reading
# after the gap.
class AddCumulativeToRainGauges < ActiveRecord::Migration[8.1]
  def change
    add_column :rain_gauges, :cumulative, :boolean, null: false, default: false
  end
end
