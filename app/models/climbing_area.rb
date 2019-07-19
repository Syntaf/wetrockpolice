class ClimbingArea < ApplicationRecord
    has_many :rainy_day_areas
    has_many :watched_areas, through: :rainy_day_areas
    has_one :location, :inverse_of => :climbing_area, required: true

    accepts_nested_attributes_for :location

    validates :watched_areas, :length => { :minimum => 1 }
end
