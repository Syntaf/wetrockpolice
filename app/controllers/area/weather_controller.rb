# frozen_string_literal: true

require 'net/http'

module Area
  # Server-side proxy for the Synoptic precipitation timeseries feed.
  #
  # The watched-area Stimulus controller used to call api.synopticdata.com
  # straight from the browser, which meant shipping the API token in public
  # JavaScript. It now fetches `GET /:slug/precipitation` instead; this
  # controller holds the token (ENV, never rendered or logged), makes the one
  # request shape the chart code consumes, and caches the response per station
  # so a busy microsite costs Synoptic one upstream call every ten minutes.
  #
  # Deliberately not a general proxy: the caller supplies nothing but the
  # slug. The station id comes from the WatchedArea row, every other upstream
  # parameter is a constant, and any query parameter at all is rejected.
  class WeatherController < BaseController
    before_action :set_watched_area
    before_action :reject_query_params

    class UpstreamError < StandardError; end

    SYNOPTIC_HOST = 'api.synopticdata.com'
    SYNOPTIC_PATH = '/v2/stations/timeseries'

    # Mirrors the exact query the frontend sent when it called Synoptic
    # directly: last 20 days (28800 minutes) of hourly precipitation
    # intervals in english units. `stid` and `token` are added server-side.
    UPSTREAM_PARAMS = {
      'recent' => 28_800,
      'units' => 'english',
      'interval' => 'hour',
      'precip' => 1
    }.freeze

    # Synoptic station ids are short alphanumerics (RRKN2, AV151, E1734).
    # Validated even though the value comes from our own database, so a
    # malformed admin entry can never turn into a strange upstream request.
    STATION_FORMAT = /\A[A-Za-z0-9]{3,10}\z/.freeze

    CACHE_TTL = 10.minutes
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10

    def show
      station = @watched_area.station.to_s
      return service_unavailable('station is not configured') unless station.match?(STATION_FORMAT)

      token = ENV.fetch('SYNOPTIC_API_TOKEN', '')
      return service_unavailable('weather service is not configured') if token.empty?

      body = Rails.cache.fetch("synoptic/precipitation/#{station}", expires_in: CACHE_TTL) do
        fetch_upstream(station, token)
      end

      render json: body
    rescue UpstreamError
      render json: { error: 'weather data is temporarily unavailable' }, status: :bad_gateway
    end

    private

    # The feature sends no query parameters, so none are accepted. This is
    # what keeps the endpoint from being usable as an open proxy.
    def reject_query_params
      return if request.query_parameters.empty?

      render json: { error: 'unexpected parameters' }, status: :bad_request
    end

    def service_unavailable(message)
      render json: { error: message }, status: :service_unavailable
    end

    # Returns the raw upstream JSON body. Raised errors deliberately carry no
    # request details: the URL contains the token, so neither the exception
    # message nor the log line may include it.
    def fetch_upstream(station, token)
      query = URI.encode_www_form(UPSTREAM_PARAMS.merge('stid' => station, 'token' => token))
      uri = URI::HTTPS.build(host: SYNOPTIC_HOST, path: SYNOPTIC_PATH, query: query)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                                     open_timeout: OPEN_TIMEOUT,
                                                     read_timeout: READ_TIMEOUT) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("Synoptic upstream returned HTTP #{response.code}")
        raise UpstreamError
      end

      response.body
    rescue Timeout::Error, IOError, SystemCallError, SocketError,
           OpenSSL::SSL::SSLError, Net::ProtocolError => e
      Rails.logger.warn("Synoptic upstream error: #{e.class}")
      raise UpstreamError
    end
  end
end
