# frozen_string_literal: true

class RainyDayArea < ApplicationRecord
  belongs_to :climbing_area
  belongs_to :watched_area
end
