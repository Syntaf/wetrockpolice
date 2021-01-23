class AddManualWarningFlagToWatchedAreas < ActiveRecord::Migration[6.0]
  def change
    add_column :watched_areas, :manual_warn, :boolean, null: false, default: false
  end
end
