# frozen_string_literal: true

require 'application_system_test_case'

# Red Rock has an alternate gauge (SNCC's Black Velvet gauge on CampbellCloud),
# so its hero title is a button that swaps the tiles and chart between gauges.
# Runs the real proxy path like watched_area_weather_proxy_test.rb, with only
# the Synoptic and CampbellCloud hops stubbed.
class WatchedAreaGaugeSwitchTest < ApplicationSystemTestCase
  WAIT = 15
  CAMPBELL_HOST = 'https://us-west-2.campbell-cloud.com'
  CAMPBELL_ORG = '4b170721-0e5f-4158-bbdc-3d9d0f4ab2f4'
  ENV_KEYS = %w[MOCK_WEATHER_DATA SYNOPTIC_API_TOKEN CAMPBELL_CLOUD_ORGANIZATION_ID
                CAMPBELL_CLOUD_USERNAME CAMPBELL_CLOUD_PASSWORD].freeze

  setup do
    @previous_env = ENV_KEYS.index_with { |key| ENV.fetch(key, nil) }
    ENV['MOCK_WEATHER_DATA'] = 'false'
    ENV['SYNOPTIC_API_TOKEN'] = 'system-test-token'
    ENV['CAMPBELL_CLOUD_ORGANIZATION_ID'] = CAMPBELL_ORG
    ENV['CAMPBELL_CLOUD_USERNAME'] = 'wrp-reader@example.com'
    ENV['CAMPBELL_CLOUD_PASSWORD'] = 'system-test-password'

    # Red Rock's primary gauge: the 2024 fixture, so its last rain is long ago.
    stub_request(:get, 'https://api.synopticdata.com/v2/stations/timeseries')
      .with(query: hash_including('stid' => 'RRKN2'))
      .to_return(status: 200, body: file_fixture('synoptic_timeseries.json').read,
                 headers: { 'Content-Type' => 'application/json' })

    stub_black_velvet(rained_hours_ago: 5)
  end

  teardown do
    @previous_env.each { |key, value| ENV[key] = value }
  end

  test 'clicking the area name switches the tiles and chart to the Black Velvet gauge' do
    visit '/redrock'

    assert_selector 'h1', text: 'Did it rain in Red Rock?'
    assert_selector '.gauge-callout', text: 'Black Velvet'
    assert_selector '[data-watched-area-target="daysTile"]', text: /\A\d{2,}\z/, wait: WAIT

    click_button 'Red Rock'

    assert_selector 'h1', text: 'Did it rain in Black Velvet?'
    assert_selector '.gauge-callout', text: 'Red Rock'
    # Rain 5 hours ago at the Black Velvet gauge: same day.
    assert_selector '[data-watched-area-target="daysTile"]', text: /\A0\z/, wait: WAIT
    assert_no_selector '[data-watched-area-target="loading"]', wait: WAIT
    assert_selector 'canvas#timeSeries'
    assert_equal 'gauge=black-velvet', URI(current_url).query

    # ...and back again
    click_button 'Black Velvet'

    assert_selector 'h1', text: 'Did it rain in Red Rock?'
    assert_selector '[data-watched-area-target="daysTile"]', text: /\A\d{2,}\z/, wait: WAIT
    assert_nil URI(current_url).query
  end

  test '?gauge= opens the page on that gauge' do
    visit '/redrock?gauge=black-velvet'

    assert_selector 'h1', text: 'Did it rain in Black Velvet?'
    assert_selector '[data-watched-area-target="daysTile"]', text: /\A0\z/, wait: WAIT
  end

  test 'a returning visitor opens on the gauge they last looked at' do
    visit '/redrock'
    click_button 'Red Rock'
    assert_selector 'h1', text: 'Did it rain in Black Velvet?'

    visit '/redrock'

    assert_selector 'h1', text: 'Did it rain in Black Velvet?'
    assert_selector '[data-watched-area-target="daysTile"]', text: /\A0\z/, wait: WAIT
    assert_equal 'gauge=black-velvet', URI(current_url).query

    # Switching back to the primary gauge forgets the preference.
    click_button 'Black Velvet'
    assert_selector 'h1', text: 'Did it rain in Red Rock?'

    visit '/redrock'

    assert_selector 'h1', text: 'Did it rain in Red Rock?'
    assert_selector '[data-watched-area-target="daysTile"]', text: /\A\d{2,}\z/, wait: WAIT
  end

  test 'areas without alternate gauges keep a plain title' do
    stub_request(:get, 'https://api.synopticdata.com/v2/stations/timeseries')
      .with(query: hash_including('stid' => 'AV151'))
      .to_return(status: 200, body: file_fixture('synoptic_timeseries.json').read)
    RainGauge.where(watched_area: watched_areas(:castlerock)).delete_all

    visit '/castlerock'

    assert_selector 'h1', text: 'Did it rain in Castle Rock?'
    assert_no_selector 'button.gauge-switch'
    assert_no_selector '.gauge-callout'
  end

  private

  def stub_black_velvet(rained_hours_ago:)
    stub_request(:post, "#{CAMPBELL_HOST}/api/v1/tokens")
      .to_return(status: 200, body: { access_token: 'system-bearer', expires_in: 3600 }.to_json)
    stub_request(:get, "#{CAMPBELL_HOST}/api/v1/organizations/#{CAMPBELL_ORG}/datastreams")
      .with(query: hash_including('stationId' => rain_gauges(:black_velvet).station))
      .to_return(status: 200,
                 body: [{ id: 'ds-1', metadata: { table: 'Rain_30min', field: 'Rain_in_Tot' } }].to_json)

    now = (Time.current.to_f * 1000).to_i
    half_hour = 1_800_000
    points = (0...(48 * 3)).map do |i|
      { ts: now - (i * half_hour), value: i == rained_hours_ago * 2 ? 0.12 : 0.0 }
    end
    stub_request(:get, "#{CAMPBELL_HOST}/api/v1/organizations/#{CAMPBELL_ORG}/datastreams/ds-1/datapoints")
      .with(query: hash_including('brief' => 'true'))
      .to_return(status: 200, body: { data: points.reverse }.to_json)
  end
end
