# frozen_string_literal: true

require 'application_system_test_case'

# What the precipitation chart's bars mean (#118): one bar per calendar day
# with today included and nothing counted twice, 7 days of hourly bars, and no
# bars overlapping on a phone-width screen.
#
# Uses the bundled fixture (MOCK_WEATHER_DATA), like watched_area_weather_test:
# 480 hourly readings ending at LAST_READING, with 0.17in of rain in all. The
# chart itself is read through Stimulus, which application.js exposes as
# window.Stimulus.
class WatchedAreaChartTest < ApplicationSystemTestCase
  WAIT = 15
  FIRST_READING = '2024-09-02T00:34:00Z'
  LAST_READING = '2024-09-21T23:34:00Z'
  FIXTURE_TOTAL_INCHES = 0.17
  HOURLY_BARS = 7 * 24
  PHONE_WIDTH = 375
  PHONE_HEIGHT = 812

  CONTROLLER_JS = "Stimulus.getControllerForElementAndIdentifier(document.body, 'watched-area')"

  setup do
    @previous_mock_weather_data = ENV['MOCK_WEATHER_DATA']
    ENV['MOCK_WEATHER_DATA'] = '1'
  end

  teardown do
    ENV['MOCK_WEATHER_DATA'] = @previous_mock_weather_data
    page.driver.browser.execute_cdp('Emulation.clearDeviceMetricsOverride')
  end

  test 'daily bars are whole calendar days, ending today, with every reading counted once' do
    visit_chart

    chart = chart_state

    # Every local calendar day the readings touch, in order. The last one is
    # the fixture's "today", which used to be dropped.
    assert_equal calendar_days_between(FIRST_READING, LAST_READING), chart['dailyDays']
    assert_equal local_day(LAST_READING), chart['dailyDays'].last
    assert_in_delta FIXTURE_TOTAL_INCHES, chart['values'].sum, 1e-9
    assert_equal 'Rain per day (inches)', chart['legend']
    assert_match(/one calendar day, midnight to midnight/, description_text)
  end

  test 'the hourly switch shows the last 7 days of hourly bars and switches back' do
    visit_chart
    daily_bars = chart_state['values'].size

    toggle_graph

    chart = chart_state

    assert_equal HOURLY_BARS, chart['values'].size
    assert_equal 'Rain per hour (inches)', chart['legend']
    assert_match(/one hour, over the last 7 days/, description_text)
    # The last bar is the latest reading, the first is 167 hours before it.
    assert_equal iso_hours_before(LAST_READING, 0), chart['hourlyTimes'].last
    assert_equal iso_hours_before(LAST_READING, HOURLY_BARS - 1), chart['hourlyTimes'].first

    toggle_graph

    assert_equal daily_bars, chart_state['values'].size
    assert_equal 'Rain per day (inches)', chart_state['legend']
  end

  test 'bars never overlap on a phone-width screen' do
    emulate_phone
    visit_chart

    assert_bars_clear('daily')

    toggle_graph

    assert_bars_clear('hourly')
  end

  private

  def visit_chart
    visit '/redrock'
    assert_no_selector '[data-watched-area-target="loading"]', wait: WAIT
    assert_selector 'canvas#timeSeries'
  end

  # A real window can't be made this narrow (Chrome has a minimum width), so
  # emulate the viewport the way DevTools' device mode does.
  def emulate_phone
    page.driver.browser.execute_cdp('Emulation.setDeviceMetricsOverride',
                                    width: PHONE_WIDTH, height: PHONE_HEIGHT,
                                    deviceScaleFactor: 1, mobile: true)
  end

  def toggle_graph
    find('[data-watched-area-target="graphToggle"]').click
  end

  def description_text
    find('[data-watched-area-target="graphDescription"]').text
  end

  # Uses each bar's final position (getProps with `true`), not wherever the
  # entry animation happens to have got to.
  def chart_state
    page.evaluate_script(<<~JS)
      (() => {
        const controller = #{CONTROLLER_JS};
        const chart = controller.timeSeriesChart;
        const bars = chart.getDatasetMeta(0).data
          .map(bar => bar.getProps(['x', 'width'], true));

        return {
          values: chart.data.datasets[0].data,
          legend: chart.data.datasets[0].label,
          dailyDays: controller.timeSeriesDailyData.map(d => d.label.toDateString()),
          hourlyTimes: controller.timeSeriesHourlyData.map(d => d.label.toISOString()),
          chartWidth: chart.width,
          bars
        };
      })()
    JS
  end

  def assert_bars_clear(mode)
    state = chart_state

    assert_operator state['chartWidth'], :<=, PHONE_WIDTH,
                    'the chart did not shrink to the phone-width window'

    state['bars'].each_cons(2).with_index do |(left, right), index|
      gap = (right['x'] - (right['width'] / 2)) - (left['x'] + (left['width'] / 2))

      assert_operator gap, :>=, 0, "#{mode} bars #{index} and #{index + 1} overlap by #{-gap}px"
    end
  end

  # The browser's time zone decides the calendar days, so ask the browser.
  def calendar_days_between(first, last)
    page.evaluate_script(<<~JS)
      (() => {
        const days = [];
        for (let t = Date.parse('#{first}'); t <= Date.parse('#{last}'); t += 3600000) {
          const day = new Date(t).toDateString();
          if (days[days.length - 1] !== day) days.push(day);
        }
        return days;
      })()
    JS
  end

  def local_day(iso)
    page.evaluate_script("new Date('#{iso}').toDateString()")
  end

  def iso_hours_before(iso, hours)
    (Time.iso8601(iso) - (hours * 3600)).utc.iso8601(3).sub('+00:00', 'Z')
  end
end
