# frozen_string_literal: true

require 'application_system_test_case'

# Climbers should wait 24 to 72 hours after rain. Until 72 hours have passed,
# the title says how many ("The last recorded precipitation was 30 hours ago
# on September 20th") and a warning shows under it; after that the title is
# the plain "was on September 20th". With the development sample data, "now"
# is its last reading.
#
# Needs rain at a known time before now, so, like watched_area_weather_proxy_test,
# it stubs the Synoptic hop behind the Rails proxy with readings generated
# relative to the current time. Open-Meteo's modeled rain is blocked in the
# browser: real rain there could otherwise stand in for the gauge's.
class WatchedAreaRainHeaderTest < ApplicationSystemTestCase
  WAIT = 15
  READINGS = 100
  HEADER = '[data-watched-area-target="rainHeader"]'
  WARNING = '[data-watched-area-target="rainWarning"]'

  setup do
    @previous_mock_weather_data = ENV['MOCK_WEATHER_DATA']
    @previous_token = ENV['SYNOPTIC_API_TOKEN']
    # 'false', not unset: see watched_area_weather_proxy_test
    ENV['MOCK_WEATHER_DATA'] = 'false'
    ENV['SYNOPTIC_API_TOKEN'] = 'system-test-token'

    page.driver.browser.execute_cdp('Network.enable')
    page.driver.browser.execute_cdp('Network.setBlockedURLs', urls: ['*open-meteo.com*'])
  end

  teardown do
    page.driver.browser.execute_cdp('Network.setBlockedURLs', urls: [])
    ENV['MOCK_WEATHER_DATA'] = @previous_mock_weather_data
    ENV['SYNOPTIC_API_TOKEN'] = @previous_token
  end

  test 'rain under 72 hours ago puts the hours in the title, with the climbing warning' do
    stub_synoptic(rain_hours_ago: 30)
    visit '/redrock'

    assert_selector HEADER, exact_text: 'The last recorded precipitation was 30 hours ago on', wait: WAIT
    assert_selector WARNING, exact_text: 'Avoid climbing 24-72 hours after rain.'
  end

  test 'rain 72 hours ago or more keeps the plain title and no warning' do
    stub_synoptic(rain_hours_ago: 72)
    visit '/redrock'

    assert_no_selector '[data-watched-area-target="loading"]', wait: WAIT
    assert_selector '[data-watched-area-target="lastRainDate"]', text: /\S/
    assert_selector HEADER, exact_text: 'The last recorded precipitation was on'
    assert_no_selector WARNING
  end

  # The development fixture is a 2024 snapshot whose last rain (0.13in at
  # 2024-09-20T14:34Z) is 33 hours before its last reading. In development
  # the page counts from that last reading, so the title, the tiles and the
  # chart's shading agree, as they would have that evening.
  test 'with the sample data, the page counts back from its last reading' do
    ENV['MOCK_WEATHER_DATA'] = '1'
    visit '/redrock'

    assert_selector HEADER, exact_text: 'The last recorded precipitation was 33 hours ago on', wait: WAIT
    assert_selector WARNING, exact_text: 'Avoid climbing 24-72 hours after rain.'
    assert_selector '[data-watched-area-target="daysTile"]', exact_text: '1'
    assert_selector '[data-watched-area-target="hoursTile"]', exact_text: '9'
  end

  private

  # READINGS hourly readings ending now, dry except for the one
  # `rain_hours_ago` hours back. The browser measures from a moment later,
  # so 30 reads as 30 hours (and a few seconds) and 72 as just over 72.
  def stub_synoptic(rain_hours_ago:)
    now = Time.now.utc
    hours_ago = (0...READINGS).to_a.reverse
    body = {
      'SUMMARY' => { 'RESPONSE_CODE' => 1, 'RESPONSE_MESSAGE' => 'OK', 'NUMBER_OF_OBJECTS' => 1 },
      'STATION' => [{
        'STID' => 'RRKN2',
        'OBSERVATIONS' => {
          'date_time' => hours_ago.map { |h| (now - (h * 3600)).iso8601 },
          'precip_intervals_set_1d' => hours_ago.map { |h| h == rain_hours_ago ? 0.05 : 0.0 }
        }
      }]
    }

    stub_request(:get, 'https://api.synopticdata.com/v2/stations/timeseries')
      .with(query: hash_including('stid' => 'RRKN2', 'token' => 'system-test-token'))
      .to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
  end
end
