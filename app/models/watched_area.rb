class WatchedArea < ApplicationRecord
    has_many :rainy_day_areas
    has_many :climbing_areas, through: :rainy_day_areas

    belongs_to :local_climbing_org
end
