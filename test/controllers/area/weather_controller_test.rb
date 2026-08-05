# frozen_string_literal: true

require 'test_helper'

# The weather proxy is the only place the app talks to the internet, and the
# only place the Synoptic token exists. These tests pin both halves of that
# contract: the response shape the watched-area JS consumes on the way out,
# and the token staying out of every body and every non-upstream request.
class WeatherControllerTest < ActionDispatch::IntegrationTest
  UPSTREAM_URL = 'https://api.synopticdata.com/v2/stations/timeseries'
  TOKEN = 'controller-test-token'

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

  private

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
