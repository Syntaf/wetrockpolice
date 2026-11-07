# frozen_string_literal: true

class WatchedArea < ApplicationRecord
  has_many :rainy_day_areas, dependent: :destroy
  has_many :climbing_areas, through: :rainy_day_areas
  has_many :faqs, dependent: :destroy
  # Alternate gauges the hero title can switch to; `station` stays primary.
  has_many :rain_gauges, -> { order(:position, :id) }, inverse_of: :watched_area, dependent: :destroy

  belongs_to :local_climbing_org
end
