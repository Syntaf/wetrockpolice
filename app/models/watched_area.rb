# frozen_string_literal: true

class WatchedArea < ApplicationRecord
  has_many :rainy_day_areas, dependent: :destroy
  has_many :climbing_areas, through: :rainy_day_areas
  has_many :faqs, dependent: :destroy

  belongs_to :local_climbing_org
end
