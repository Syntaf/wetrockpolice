# frozen_string_literal: true

# Partner API: per-site bearer keys, and an opt-in flag on the gauges whose
# data we're allowed to share. Only coalition-owned gauges (SNCC's Black
# Velvet gauge) qualify; Synoptic's terms (§2.4) forbid redistributing their
# data, so the primary Synoptic stations are never exposed.
class CreateApiKeysAndApiVisibleGauges < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.string :name, null: false
      # SHA-256 of the key; the key itself is shown once and never stored.
      t.string :token_digest, null: false
      t.boolean :active, null: false, default: true
      t.datetime :last_used_at
      t.timestamps
    end
    add_index :api_keys, :token_digest, unique: true

    add_column :rain_gauges, :api_visible, :boolean, null: false, default: false
  end
end
