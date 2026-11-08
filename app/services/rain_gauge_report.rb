# frozen_string_literal: true

# The partner API's normalized view of one gauge, built from the
# Synoptic-shaped JSON every gauge feed produces (see
# CampbellCloudPrecipitation#synoptic_shape). Provider details stay internal:
# partners get hourly inches plus the summary the site's tiles show.
class RainGaugeReport
  TOTAL_WINDOWS = { '24h' => 24.hours, '72h' => 72.hours, '7d' => 7.days }.freeze

  def initialize(gauge, body, now: Time.current)
    @gauge = gauge
    @hourly = parse(body)
    @now = now
  end

  def as_json(*)
    last_rain_at = @hourly.reverse_each.find { |hour| hour[:precip].to_f.positive? }&.dig(:end)

    {
      id: @gauge.slug,
      name: @gauge.name,
      status: 'ok',
      last_rain_at: last_rain_at&.iso8601,
      hours_since_rain: last_rain_at && ((@now - last_rain_at) / 1.hour).floor,
      totals: TOTAL_WINDOWS.transform_values { |window| total_since(@now - window) },
      hourly: @hourly.map { |hour| { end: hour[:end].iso8601, precip: hour[:precip] } }
    }
  end

  # A gauge whose provider is failing right now: still listed, so partners
  # can tell "no data at the moment" from "this gauge doesn't exist".
  def self.unavailable(gauge)
    { id: gauge.slug, name: gauge.name, status: 'unavailable',
      last_rain_at: nil, hours_since_rain: nil, totals: nil, hourly: [] }
  end

  private

  # Hours with no reading stay nil (no data), which is different from 0.
  def parse(body)
    observations = JSON.parse(body).dig('STATION', 0, 'OBSERVATIONS') || {}
    times = observations['date_time'] || []
    values = observations['precip_intervals_set_1d'] || []

    times.zip(values).map do |time, value|
      { end: Time.iso8601(time), precip: value&.to_f&.round(3) }
    end
  end

  def total_since(start)
    @hourly.select { |hour| hour[:end] > start }.sum { |hour| hour[:precip].to_f }.round(3)
  end
end
