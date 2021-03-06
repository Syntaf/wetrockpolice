# frozen_string_literal: true

class Location < ApplicationRecord
  belongs_to :climbing_area, :inverse_of => :location
  has_many :rainy_day_areas, through: :climbing_area
  has_many :watched_areas, through: :rainy_day_areas

  validates :longitude, presence: true
  validates :latitude, presence: true
end
