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

  # What the hero caption calls an area's primary gauge ("Tap the name to check
  # the Visitor Center gauge"); the title itself keeps the area name.
  PRIMARY_GAUGE_LABELS = {
    'redrock' => 'Visitor Center'
  }.freeze

  # An alternate gauge is captioned "new <name>" for this long after it's added.
  NEW_GAUGE_PERIOD = 90.days

  # The gauges the hero title cycles through, primary first. `station` keys
  # the Open-Meteo missed-shower points in watched_area_controller.js, so only
  # Synoptic gauges carry one; a CampbellCloud gauge sits at the crag itself
  # and is trusted as-is.
  def rain_gauge_options(watched_area)
    primary = {
      slug: '',
      name: watched_area.name,
      label: PRIMARY_GAUGE_LABELS.fetch(watched_area.slug, watched_area.name),
      station: watched_area.station.to_s,
      url: watched_area_precipitation_path(slug: watched_area.slug),
      excerpt: watched_area.info_bubble_excerpt
    }

    alternates = watched_area.rain_gauges.map do |gauge|
      {
        slug: gauge.slug,
        name: gauge.name,
        label: gauge.created_at&.after?(NEW_GAUGE_PERIOD.ago) ? "new #{gauge.name}" : gauge.name,
        station: gauge.synoptic? ? gauge.station : '',
        url: watched_area_gauge_precipitation_path(slug: watched_area.slug, gauge: gauge.slug),
        excerpt: gauge.info_bubble_excerpt.presence || watched_area.info_bubble_excerpt
      }
    end

    [primary, *alternates]
  end

  # Which gauge the page opens on: ?gauge=black-velvet makes a shareable link.
  def initial_rain_gauge_index(gauges, requested_slug)
    return 0 if requested_slug.blank?

    gauges.index { |gauge| gauge[:slug] == requested_slug } || 0
  end
end
