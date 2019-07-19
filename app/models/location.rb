class Location < ApplicationRecord
  belongs_to :climbing_area
  has_many :rainy_day_areas, through: :climbing_area
  has_many :watched_areas, through: :rainy_day_areas
end
