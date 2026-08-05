# frozen_string_literal: true

module ApplicationHelper
  # Drives the Stimulus `developmentMode` value, which swaps the live Synoptic
  # fetch for the bundled fixture. `local?` is development-or-test and is never
  # true in production, so the mock path stays unreachable for real visitors
  # even if MOCK_WEATHER_DATA leaks into a deployed environment. It widened
  # from `development?` to `local?` so the system test can exercise the weather
  # feature without a network round-trip to Synoptic.
  def development_mode?
    Rails.env.local? && ActiveModel::Type::Boolean.new.cast(ENV['MOCK_WEATHER_DATA'])
  end

  WATCHED_AREA_BG_IMAGES = {
    'redrock' => 'redrock-winter-2020-hero.jpg',
    'castlerock' => 'castlerock/hero-image.jpg',
    'stoneypoint' => 'stoneypoint/hero-image.png'
  }.freeze

  def watched_area_bg_image(watched_area)
    WATCHED_AREA_BG_IMAGES[watched_area.slug]
  end
end
