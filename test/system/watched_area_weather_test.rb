# frozen_string_literal: true

require 'application_system_test_case'

# The one end-to-end test of the app's core feature: a visitor lands on a
# microsite and sees how long it has been dry, plus the precipitation chart.
#
# Everything below the ERB is JavaScript -- Stimulus boots the watched-area
# controller from the body's data attributes, fetches observations, fills the
# day/hour tiles and instantiates a Chart.js bar chart. None of that is
# reachable from a controller test, so a pipeline regression (a broken esbuild
# bundle, an unregistered Stimulus controller, a Chart.js import that
# tree-shakes away something the bar chart needs) currently ships silently.
# This test is the guard.
#
# The observations come from the bundled fixture rather than Synoptic:
# MOCK_WEATHER_DATA makes `development_mode?` true, which flips the Stimulus
# `developmentMode` value, which makes the controller dynamically import
# app/javascript/fixtures/precipitation_response.js instead of calling the API.
# That keeps the test offline and deterministic, and it exercises the esbuild
# code-splitting chunk at the same time.
class WatchedAreaWeatherTest < ApplicationSystemTestCase
  # The mock path deliberately resolves on a 1.5s setTimeout to imitate network
  # latency, so the tiles cannot be populated within Capybara's 2s default.
  # Give the assertions room without making a genuine hang slow.
  WAIT = 15

  # Each tile holds either an integer count or the infinity glyph the
  # controller writes when the fixture contains no rain at all.
  TILE_TEXT = /\A(\d+|∞)\z/

  setup do
    # Read per-request by ApplicationHelper#development_mode? while the page is
    # server-rendered. System tests boot Puma in this same process, so setting
    # it here -- before `visit` -- is enough; no server restart is involved.
    @previous_mock_weather_data = ENV['MOCK_WEATHER_DATA']
    ENV['MOCK_WEATHER_DATA'] = '1'
  end

  teardown do
    ENV['MOCK_WEATHER_DATA'] = @previous_mock_weather_data
  end

  test 'renders the precipitation tiles and the chart from observation data' do
    visit '/redrock'

    # Server-rendered shell: proves routing and the layout are intact before
    # any assertion starts depending on JavaScript having run.
    assert_selector 'h1', text: 'Did it rain in Red Rock?'

    # Pins the mock wiring itself. Without this, a regression in
    # `development_mode?` would silently drop the page back onto the live
    # Synoptic API, and on a networked machine the rest of the test would keep
    # passing -- a green run that proves nothing and needs the internet.
    assert_selector 'body[data-watched-area-development-mode-value="true"]', visible: :all

    # The tiles start empty behind spinner placeholders; the controller removes
    # the spinners and writes the elapsed days/hours only once the observations
    # resolve. Populated tiles therefore mean Stimulus booted, the bundle
    # loaded, the fixture chunk was fetched and served, and the parsing ran.
    assert_selector '[data-watched-area-target="daysTile"]', text: TILE_TEXT, wait: WAIT
    assert_selector '[data-watched-area-target="hoursTile"]', text: TILE_TEXT
    assert_selector '[data-watched-area-target="lastRainDate"]', text: /\S/

    assert_no_selector '[data-watched-area-target="loading"]',
                       visible: :all,
                       wait: WAIT

    # Chart.js draws into the canvas and, being `responsive: true`, sizes it to
    # its container. A canvas that exists but measures 0x0, or one sized but
    # never painted, means the chart did not instantiate -- exactly what a bad
    # tree-shake of the bar controller or its scales produces. So assert real
    # pixels: dimensions, then actual drawn (non-transparent) content.
    assert_selector 'canvas#timeSeries', wait: WAIT

    canvas = page.evaluate_script(<<~JS)
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

    assert_operator canvas['width'].to_i, :>, 0,
                    'chart canvas has zero width; Chart.js never sized it'
    assert_operator canvas['height'].to_i, :>, 0,
                    'chart canvas has zero height; Chart.js never sized it'
    assert_operator canvas['painted'].to_i, :>, 0,
                    'chart canvas is blank; Chart.js sized it but drew nothing'
  end
end
