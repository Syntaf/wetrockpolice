# frozen_string_literal: true

class RainyDayArea < ApplicationRecord
  belongs_to :climbing_area
  belongs_to :watched_area

  def as_json(*_args)
    super(
      only: %i[id driving_time climbing_area],
      include: {
        climbing_area: {
          only: %i[name rock_type description],
          include: {
            location: {
              only: %i[longitude latitude mt_z]
            }
          }
        }
      }
    )
  end
end
