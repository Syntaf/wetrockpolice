# frozen_string_literal: true

require 'test_helper'

# The weather proxy is the only place the app talks to the internet, and the
# only place the Synoptic token exists. These tests pin both halves of that
# contract: the response shape the watched-area JS consumes on the way out,
# and the token staying out of every body and every non-upstream request.
class WeatherControllerTest < ActionDispatch::IntegrationTest
  UPSTREAM_URL = 'https://api.synopticdata.com/v2/stations/timeseries'
  TOKEN = 'controller-test-token'
  CAMPBELL_HOST = 'https://us-west-2.campbell-cloud.com'
  CAMPBELL_ORG = '4b170721-0e5f-4158-bbdc-3d9d0f4ab2f4'
  CAMPBELL_TOKEN_URL = "#{CAMPBELL_HOST}/api/v1/tokens".freeze

  setup do
    @previous_token = ENV['SYNOPTIC_API_TOKEN']
    ENV['SYNOPTIC_API_TOKEN'] = TOKEN
  end

  teardown do
    ENV['SYNOPTIC_API_TOKEN'] = @previous_token
  end

  test 'passes the upstream body through in the shape the chart JS consumes' do
    stub = stub_upstream_success

    get '/redrock/precipitation'

    assert_response :success
    assert_equal 'application/json', @response.media_type

    body = JSON.parse(@response.body)
    assert_equal 1, body.dig('SUMMARY', 'RESPONSE_CODE')

    observations = body.dig('STATION', 0, 'OBSERVATIONS')
    assert_kind_of Array, observations['precip_intervals_set_1d']
    assert_kind_of Array, observations['date_time']
    assert_equal observations['date_time'].length,
                 observations['precip_intervals_set_1d'].length

    # The one legitimate upstream request: our station, our fixed window.
    assert_requested(stub)
    # The token goes upstream and nowhere else.
    assert_not_includes @response.body, TOKEN
  end

  test 'an upstream 500 becomes a clean 502 without leaking anything' do
    stub_request(:get, UPSTREAM_URL)
      .with(query: hash_including('stid' => 'RRKN2'))
      .to_return(status: 500, body: 'upstream exploded')

    get '/redrock/precipitation'

    assert_response :bad_gateway
    body = JSON.parse(@response.body)
    assert_includes body['error'], 'unavailable'
    assert_not_includes @response.body, TOKEN
  end

  test 'an upstream timeout becomes a clean 502' do
    stub_request(:get, UPSTREAM_URL)
      .with(query: hash_including('stid' => 'RRKN2'))
      .to_timeout

    get '/redrock/precipitation'

    assert_response :bad_gateway
    assert JSON.parse(@response.body)['error'].present?
  end

  test 'a missing token yields 503 and no upstream request at all' do
    ENV.delete('SYNOPTIC_API_TOKEN')
    stub = stub_upstream_success

    get '/redrock/precipitation'

    assert_response :service_unavailable
    assert JSON.parse(@response.body)['error'].present?
    assert_not_requested(stub)
  end

  test 'a second request within the TTL is served from cache, not Synoptic' do
    stub = stub_upstream_success

    # The test environment uses :null_store precisely so caching never hides
    # requests from other tests; swap in a real store to observe the hit.
    Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
      get '/redrock/precipitation'
      assert_response :success

      get '/redrock/precipitation'
      assert_response :success
    end

    assert_requested(stub, times: 1)
  end

  test 'an upstream failure is cached: repeat views do not hammer Synoptic' do
    stub = stub_request(:get, UPSTREAM_URL)
           .with(query: hash_including('stid' => 'RRKN2'))
           .to_return(status: 500, body: 'upstream exploded')

    Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
      get '/redrock/precipitation'
      assert_response :bad_gateway

      get '/redrock/precipitation'
      assert_response :bad_gateway
    end

    # One upstream attempt per failure window, not one per page view --
    # this is what keeps a Synoptic outage from parking every Puma thread
    # on a hanging call and 503ing the whole site.
    assert_requested(stub, times: 1)
  end

  test 'the failure cache expires, so recovery needs no deploy or restart' do
    stub = stub_request(:get, UPSTREAM_URL)
           .with(query: hash_including('stid' => 'RRKN2'))
           .to_return({ status: 500, body: 'blip' },
                      { status: 200,
                        body: file_fixture('synoptic_timeseries.json').read,
                        headers: { 'Content-Type' => 'application/json' } })

    Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
      get '/redrock/precipitation'
      assert_response :bad_gateway

      travel(Area::WeatherController::FAILURE_TTL + 1.second) do
        get '/redrock/precipitation'
        assert_response :success
      end
    end

    assert_requested(stub, times: 2)
  end

  test 'query parameters are rejected, so upstream params cannot be forged' do
    stub = stub_upstream_success

    get '/redrock/precipitation', params: { stid: 'OTHER', token: 'theirs' }

    assert_response :bad_request
    assert JSON.parse(@response.body)['error'].present?
    assert_not_requested(stub)
  end

  test 'an unknown slug 404s before anything else happens' do
    stub = stub_upstream_success

    get '/no-such-area/precipitation'

    assert_response :not_found
    assert_not_requested(stub)
  end

  # --- alternate gauges (/:slug/precipitation/:gauge) ---------------------

  test 'a CampbellCloud gauge is served in the same Synoptic shape' do
    with_campbell_env do
      stub_campbell_success

      get '/redrock/precipitation/black-velvet'

      assert_response :success
      body = JSON.parse(@response.body)
      assert_equal 1, body.dig('SUMMARY', 'RESPONSE_CODE')
      observations = body.dig('STATION', 0, 'OBSERVATIONS')
      assert_equal observations['date_time'].length, observations['precip_intervals_set_1d'].length
      assert_not_includes @response.body, 'campbell-test-password'
      assert_not_includes @response.body, 'campbell-bearer'
    end
  end

  test 'a CampbellCloud gauge without credentials is a 503 and no upstream call' do
    with_campbell_env(password: nil) do
      get '/redrock/precipitation/black-velvet'

      assert_response :service_unavailable
      assert_not_requested(:post, CAMPBELL_TOKEN_URL)
    end
  end

  test 'a CampbellCloud failure is a 502 and is cached like Synoptic failures' do
    with_campbell_env do
      token = stub_request(:post, CAMPBELL_TOKEN_URL).to_return(status: 500, body: 'down')

      Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
        get '/redrock/precipitation/black-velvet'
        assert_response :bad_gateway

        get '/redrock/precipitation/black-velvet'
        assert_response :bad_gateway
      end

      assert_requested token, times: 1
    end
  end

  test 'a Synoptic alternate gauge proxies its own station, not the area primary' do
    stub = stub_request(:get, UPSTREAM_URL)
           .with(query: hash_including('stid' => 'SKYL1', 'token' => TOKEN))
           .to_return(status: 200, body: file_fixture('synoptic_timeseries.json').read)

    get '/castlerock/precipitation/skyline'

    assert_response :success
    assert_requested stub
  end

  test 'gauges only resolve within their own area' do
    get '/castlerock/precipitation/black-velvet'

    assert_response :not_found
    assert_not_requested(:post, CAMPBELL_TOKEN_URL)
  end

  test 'gauge routes still reject query parameters' do
    get '/redrock/precipitation/black-velvet', params: { station: 'other' }

    assert_response :bad_request
  end

  private

  def with_campbell_env(password: 'campbell-test-password')
    keys = %w[CAMPBELL_CLOUD_ORGANIZATION_ID CAMPBELL_CLOUD_USERNAME CAMPBELL_CLOUD_PASSWORD]
    previous = keys.index_with { |key| ENV.fetch(key, nil) }
    ENV['CAMPBELL_CLOUD_ORGANIZATION_ID'] = CAMPBELL_ORG
    ENV['CAMPBELL_CLOUD_USERNAME'] = 'wrp-reader@example.com'
    ENV['CAMPBELL_CLOUD_PASSWORD'] = password
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end

  def stub_campbell_success
    stub_request(:post, CAMPBELL_TOKEN_URL)
      .to_return(status: 200, body: { access_token: 'campbell-bearer', expires_in: 3600 }.to_json)
    stub_request(:get, "#{CAMPBELL_HOST}/api/v1/organizations/#{CAMPBELL_ORG}/datastreams")
      .with(query: hash_including('stationId' => rain_gauges(:black_velvet).station))
      .to_return(status: 200, body: [{ id: 'ds-1', metadata: { table: 'Rain_30min', field: 'Rain_in_Tot' } }].to_json)

    now = (Time.current.to_f * 1000).to_i
    points = (0...96).map { |i| { ts: now - (i * 1_800_000), value: i == 10 ? 0.05 : 0.0 } }.reverse
    stub_request(:get, "#{CAMPBELL_HOST}/api/v1/organizations/#{CAMPBELL_ORG}/datastreams/ds-1/datapoints")
      .with(query: hash_including('brief' => 'true'))
      .to_return(status: 200, body: { data: points }.to_json)
  end

  # Strict param matcher: the stub only responds when the proxy sends exactly
  # the query the browser used to send, plus its own stid and token. A drift
  # in any constant fails these tests instead of silently changing the feed.
  def stub_upstream_success
    stub_request(:get, UPSTREAM_URL)
      .with(query: {
              'recent' => '28800',
              'units' => 'english',
              'interval' => 'hour',
              'precip' => '1',
              'stid' => 'RRKN2',
              'token' => TOKEN
            })
      .to_return(
        status: 200,
        body: file_fixture('synoptic_timeseries.json').read,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
