# frozen_string_literal: true

require 'application_system_test_case'

# The production wiring, end to end: MOCK_WEATHER_DATA is off, so the page
# renders with `developmentMode` false and the Stimulus controller fetches
# `/redrock/precipitation` from the very Rails server Capybara booted. That
# request runs Area::WeatherController for real -- station lookup, param
# gate, Net::HTTP call -- with only the final Synoptic hop stubbed by
# WebMock (test_helper allows localhost precisely so browser->server traffic
# flows while everything else stays blocked).
#
# Its sibling, watched_area_weather_test.rb, covers the mock-fixture path;
# together they pin both branches of fetchObservations.
class WatchedAreaWeatherProxyTest < ApplicationSystemTestCase
  WAIT = 15
  TILE_TEXT = /\A(\d+|∞)\z/.freeze

  setup do
    # Read per-request: development_mode? at render time, the token inside
    # the proxy action. The system-test server runs in this process, so
    # setting ENV here -- before `visit` -- reaches both.
    @previous_mock_weather_data = ENV['MOCK_WEATHER_DATA']
    @previous_token = ENV['SYNOPTIC_API_TOKEN']
    # Explicitly 'false', not deleted: with the variable unset the helper
    # returns nil, ERB renders the attribute as "", and Stimulus casts an
    # empty string to *true* -- which would silently flip this test onto the
    # mock path the sibling test already covers.
    ENV['MOCK_WEATHER_DATA'] = 'false'
    ENV['SYNOPTIC_API_TOKEN'] = 'system-test-token'

    stub_request(:get, 'https://api.synopticdata.com/v2/stations/timeseries')
      .with(query: hash_including('stid' => 'RRKN2', 'token' => 'system-test-token'))
      .to_return(
        status: 200,
        body: file_fixture('synoptic_timeseries.json').read,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  teardown do
    ENV['MOCK_WEATHER_DATA'] = @previous_mock_weather_data
    ENV['SYNOPTIC_API_TOKEN'] = @previous_token
  end

  test 'renders the tiles and chart from data proxied through the Rails server' do
    visit '/redrock'

    assert_selector 'h1', text: 'Did it rain in Red Rock?'

    # Proves this test is on the live-fetch branch, not the bundled fixture:
    # were developmentMode true, the proxy and the WebMock stub above would
    # never be touched and this test would duplicate the mock-path one.
    assert_selector 'body[data-watched-area-development-mode-value="false"]', visible: :all

    # Populated tiles mean the browser hit /redrock/precipitation, the proxy
    # called (stubbed) Synoptic, and the JS parsed the passthrough response.
    assert_selector '[data-watched-area-target="daysTile"]', text: TILE_TEXT, wait: WAIT
    assert_selector '[data-watched-area-target="hoursTile"]', text: TILE_TEXT
    assert_selector '[data-watched-area-target="lastRainDate"]', text: /\S/

    assert_no_selector '[data-watched-area-target="loading"]',
                       visible: :all,
                       wait: WAIT

    # Same painted-pixels bar as the mock-path test: a sized-but-blank canvas
    # means Chart.js never drew, however healthy the network hops looked.
    assert_selector 'canvas#timeSeries', wait: WAIT

    canvas = chart_canvas_metrics

    assert_operator canvas['width'].to_i, :>, 0,
                    'chart canvas has zero width; Chart.js never sized it'
    assert_operator canvas['height'].to_i, :>, 0,
                    'chart canvas has zero height; Chart.js never sized it'
    assert_operator canvas['painted'].to_i, :>, 0,
                    'chart canvas is blank; Chart.js sized it but drew nothing'

    # The token's job ended at the stubbed upstream hop; the page the visitor
    # received must not contain it anywhere.
    assert_no_match(/system-test-token/, page.html)
  end

  private

  def chart_canvas_metrics
    page.evaluate_script(<<~JS)
      (() => {
        const el = document.getElementById('timeSeries');
        const ctx = el.getContext('2d');
        const { width, height } = el;
        let painted = 0;

        if (width > 0 && height > 0) {
          const pixels = ctx.getImageData(0, 0, width, height).data;
          for (let i = 3; i < pixels.length; i += 4) {
            if (pixels[i] !== 0) painted++;
          }
        }

        return { width, height, painted };
      })()
    JS
  end
end
