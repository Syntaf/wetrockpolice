class ClimbingArea < ApplicationRecord
    has_many :rainy_day_areas
    has_many :watched_areas, through: :rainy_day_areas
    has_one :location
end
