# frozen_string_literal: true

class LocalClimbingOrg < ApplicationRecord
  has_many :watched_areas, dependent: :nullify
end
