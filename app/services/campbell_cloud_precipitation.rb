# frozen_string_literal: true

require 'net/http'

# Pulls a CampbellCloud rain gauge's recent per-interval totals and returns
# them as a JSON string in the same shape Synoptic's timeseries endpoint uses
# (SUMMARY / STATION[0].OBSERVATIONS.{date_time, precip_intervals_set_1d}),
# so the watched-area chart code can consume either provider unchanged.
#
# CampbellCloud v1 REST API (https://<host>/api/v1/docs/):
#   POST /api/v1/tokens                                   password grant -> bearer (3600s)
#   GET  /api/v1/organizations/:org/datastreams?stationId= list a station's datastreams
#   GET  /api/v1/organizations/:org/datastreams/:id/datapoints?startEpoch=&endEpoch=&limit=&brief=true
#
# The API has no API keys, so this logs in as a (read-only) CampbellCloud
# user from ENV. Neither the password nor the bearer token is ever logged,
# rendered or included in an exception message.
class CampbellCloudPrecipitation < ApplicationService
  class Error < StandardError; end
  class NotConfigured < Error; end
  class Unauthorized < Error; end

  DEFAULT_HOST = 'us-west-2.campbell-cloud.com'
  CLIENT_ID = 'cloud'

  # Same 20-day window the Synoptic proxy asks for (recent=28800 minutes).
  WINDOW = 20.days
  # API maximum for a single datapoints request; 20 days of 5-minute data
  # is under 6,000 points, so one request covers any sane logging interval.
  MAX_POINTS = 15_000

  TOKEN_CACHE_KEY = 'campbell_cloud/access_token'
  # Datastream ids only change if the logger program is re-deployed.
  DATASTREAM_TTL = 1.day
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 10

  def self.configured?
    %w[CAMPBELL_CLOUD_ORGANIZATION_ID CAMPBELL_CLOUD_USERNAME CAMPBELL_CLOUD_PASSWORD]
      .all? { |key| ENV.fetch(key, '').present? }
  end

  def initialize(gauge, now: Time.current)
    super()
    @gauge = gauge
    @now = now
  end

  def call
    raise NotConfigured, 'CampbellCloud credentials are not configured' unless self.class.configured?

    points = fetch_datapoints(datastream_id)
    series = HourlySeries.build(points, units: @gauge.units)
    raise Error, 'gauge returned no datapoints' if series.empty?

    JSON.generate(synoptic_shape(series))
  end

  # Turns CampbellCloud datapoints ({ "ts" => ms, "value" => n }) into an
  # evenly spaced hourly series of rain totals in inches. Plain Ruby so it's
  # testable without HTTP.
  module HourlySeries
    HOUR_MS = 3_600_000
    MM_PER_INCH = 25.4

    module_function

    # Each reading is a per-interval total stamped at the END of its
    # interval, so it belongs to the hour that ends at or after its stamp
    # (02:30 and 03:00 both fill the hour ending 03:00). Hours with no
    # readings at all are nil (no data), not 0 (no rain).
    def build(points, units: 'in')
      totals = Hash.new(0.0)

      Array(points).each do |point|
        ts = point['ts']
        value = numeric(point['value'])
        next unless ts.is_a?(Integer) && value

        bucket = ((ts + HOUR_MS - 1) / HOUR_MS) * HOUR_MS
        totals[bucket] += value
      end

      return [] if totals.empty?

      first, last = totals.keys.minmax
      (first..last).step(HOUR_MS).map do |bucket|
        value = totals.key?(bucket) ? to_inches(totals[bucket], units) : nil
        [Time.at(bucket / 1000).utc.iso8601, value]
      end
    end

    # Loggers report NAN / INF for a failed measurement; negative rain is a
    # sensor fault. Neither is a reading.
    def numeric(value)
      number = Float(value, exception: false)
      return nil if number.nil? || !number.finite? || number.negative?

      number
    end

    def to_inches(value, units)
      inches = units == 'mm' ? value / MM_PER_INCH : value
      inches.round(4)
    end
  end

  private

  def synoptic_shape(series)
    {
      'SUMMARY' => {
        'NUMBER_OF_OBJECTS' => 1,
        'RESPONSE_CODE' => 1,
        'RESPONSE_MESSAGE' => 'OK',
        'PROVIDER' => 'CampbellCloud'
      },
      'UNITS' => { 'precip_intervals' => 'Inches' },
      'STATION' => [{
        'STID' => @gauge.slug,
        'NAME' => @gauge.name,
        'OBSERVATIONS' => {
          'date_time' => series.map(&:first),
          'precip_intervals_set_1d' => series.map(&:last)
        }
      }]
    }
  end

  def datastream_id
    key = "campbell_cloud/datastream/#{@gauge.station}/#{@gauge.campbell_table}/#{@gauge.campbell_field}"
    Rails.cache.fetch(key, expires_in: DATASTREAM_TTL) { find_datastream_id }
  end

  def find_datastream_id
    datastreams = authorized_get(org_path('datastreams'), stationId: @gauge.station, limit: 250)

    match = Array(datastreams).find do |ds|
      ds.dig('metadata', 'table') == @gauge.campbell_table &&
        ds.dig('metadata', 'field') == @gauge.campbell_field
    end

    raise Error, "no datastream #{@gauge.campbell_table}.#{@gauge.campbell_field} on station" unless match

    match['id']
  end

  def fetch_datapoints(id)
    end_ms = (@now.to_f * 1000).to_i
    start_ms = ((@now - WINDOW).to_f * 1000).to_i

    body = authorized_get(org_path("datastreams/#{id}/datapoints"),
                          startEpoch: start_ms, endEpoch: end_ms, limit: MAX_POINTS, brief: true)

    if body.dig('range', 'exceeded_request')
      Rails.logger.warn("CampbellCloud datapoints truncated at #{MAX_POINTS} for gauge #{@gauge.slug}")
    end

    body['data']
  end

  # One retry with a fresh token: a cached token can be revoked or expire
  # early, and that shouldn't cost a whole failure window.
  def authorized_get(path, params)
    retried = false
    begin
      request_json(Net::HTTP::Get, path, params: params, token: access_token)
    rescue Unauthorized
      Rails.cache.delete(TOKEN_CACHE_KEY)
      raise Error, 'CampbellCloud rejected the credentials' if retried

      retried = true
      retry
    end
  end

  def access_token
    cached = Rails.cache.read(TOKEN_CACHE_KEY)
    return cached if cached.present?

    body = request_json(Net::HTTP::Post, '/api/v1/tokens', json: {
                          username: ENV.fetch('CAMPBELL_CLOUD_USERNAME'),
                          password: ENV.fetch('CAMPBELL_CLOUD_PASSWORD'),
                          client_id: CLIENT_ID,
                          grant_type: 'password'
                        })

    token = body['access_token']
    raise Error, 'CampbellCloud token response had no access_token' if token.blank?

    # Expire a minute early so a token never dies mid-request.
    ttl = [body['expires_in'].to_i - 60, 60].max
    Rails.cache.write(TOKEN_CACHE_KEY, token, expires_in: ttl.seconds)
    token
  end

  def org_path(suffix)
    "/api/v1/organizations/#{ENV.fetch('CAMPBELL_CLOUD_ORGANIZATION_ID')}/#{suffix}"
  end

  def host
    ENV.fetch('CAMPBELL_CLOUD_HOST', '').presence || DEFAULT_HOST
  end

  def request_json(verb, path, params: nil, json: nil, token: nil)
    uri = URI::HTTPS.build(host: host, path: path, query: params && URI.encode_www_form(params))
    request = verb.new(uri)
    request['Accept'] = 'application/json'
    request['Authorization'] = "Bearer #{token}" if token
    if json
      request['Content-Type'] = 'application/json'
      request.body = JSON.generate(json)
    end

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                                   open_timeout: OPEN_TIMEOUT,
                                                   read_timeout: READ_TIMEOUT) do |http|
      http.request(request)
    end

    check_response!(response, "#{verb::METHOD} #{path_for_log(path)}", authenticated: token.present?)
    JSON.parse(response.body)
  rescue JSON::ParserError
    raise Error, 'CampbellCloud returned a non-JSON body'
  rescue Timeout::Error, IOError, SystemCallError, SocketError,
         OpenSSL::SSL::SSLError, Net::ProtocolError => e
    Rails.logger.warn("CampbellCloud request error: #{e.class}")
    raise Error, "CampbellCloud request failed (#{e.class})"
  end

  # A 401 on an authenticated call means a stale token (retried by
  # authorized_get); a 401 on login itself is bad credentials, a plain Error.
  def check_response!(response, description, authenticated:)
    raise Unauthorized, 'CampbellCloud returned 401' if authenticated && response.is_a?(Net::HTTPUnauthorized)
    return if response.is_a?(Net::HTTPSuccess)

    Rails.logger.warn("CampbellCloud returned HTTP #{response.code} for #{description}")
    raise Error, "CampbellCloud returned HTTP #{response.code}"
  end

  # Paths carry only ids, never credentials, but keep the log line short.
  def path_for_log(path)
    path.sub(%r{/organizations/[^/]+}, '/organizations/:org')
  end
end
