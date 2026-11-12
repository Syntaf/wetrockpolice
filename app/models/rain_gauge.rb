# frozen_string_literal: true

# An alternate rain gauge for a watched area. The area's own `station` is
# still its primary (Synoptic) gauge; rows here are the extra gauges the hero
# title can switch to, served by GET /:slug/precipitation/:gauge.
class RainGauge < ApplicationRecord
  PROVIDERS = %w[synoptic campbell_cloud].freeze
  UNITS = %w[in mm].freeze

  # Same shape the weather proxy enforces for Synoptic ids.
  SYNOPTIC_STATION_FORMAT = /\A[A-Za-z0-9]{3,10}\z/.freeze
  UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/.freeze
  # Campbell datalogger table/field names (Rain_30min, Rain_in_Tot)
  CAMPBELL_NAME_FORMAT = /\A[A-Za-z0-9_()]{1,64}\z/.freeze

  belongs_to :watched_area

  validates :name, presence: true
  validates :slug, presence: true,
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ },
                   uniqueness: { scope: :watched_area_id }
  validates :provider, inclusion: { in: PROVIDERS }
  validates :units, inclusion: { in: UNITS }
  validates :station, presence: true
  validates :station, format: { with: SYNOPTIC_STATION_FORMAT }, if: :synoptic?
  validates :station, format: { with: UUID_FORMAT, message: 'must be the CampbellCloud station UUID' },
                      if: :campbell_cloud?
  validates :campbell_table, :campbell_field,
            presence: true, format: { with: CAMPBELL_NAME_FORMAT }, if: :campbell_cloud?
  # Synoptic's terms (§2.4) forbid redistributing their data to third
  # parties, so only gauges whose data we own (SNCC's) can be shared.
  validates :api_visible, absence: { message: "can't be set on Synoptic gauges: their terms forbid redistribution" },
                          if: :synoptic?

  # Gauges the partner API (Api::V1) may serve.
  scope :api_visible, -> { where(api_visible: true) }

  def synoptic?
    provider == 'synoptic'
  end

  def campbell_cloud?
    provider == 'campbell_cloud'
  end

  # rails_admin renders a select for these
  def provider_enum
    PROVIDERS
  end

  def units_enum
    UNITS
  end
end
