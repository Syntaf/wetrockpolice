class ClimbingArea < ApplicationRecord
    validate :validate_watched_areas

    has_many :rainy_day_areas
    has_many :watched_areas, through: :rainy_day_areas
    has_one :location, :inverse_of => :climbing_area, required: true

    accepts_nested_attributes_for :location

    validates :name, presence: true
    validates :rock_type, presence: true

    def validate_watched_areas
        errors.add(:watched_areas, :too_short) unless self.watched_areas.length > 0
    end
end
