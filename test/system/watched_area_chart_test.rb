# frozen_string_literal: true

require 'application_system_test_case'

# What the precipitation chart's bars mean (#118): one bar per calendar day
# with today included and nothing counted twice, 5 days of hourly bars, the
# last 24/48/72 hours shaded and labelled behind them, headroom above the
# tallest bar, and, on a phone-width screen, fewer days (so each has room for
# its label) with no bars overlapping each other or a gridline.
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
  HOURLY_BARS = 5 * 24
  WINDOW_LABELS = %w[24h 48h 72h].freeze
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
    # A desktop window has room for every day
    assert_equal chart['dailyDays'].size, chart['values'].size
    assert_in_delta FIXTURE_TOTAL_INCHES, chart['values'].sum, 1e-9
    assert_equal 'Rain per day (inches)', chart['legend']
    assert_match(/one calendar day, midnight to midnight/, description_text)
    assert_axis_dates_plain(chart, 'daily')
    assert_equal expected_axis_labels(chart['dailyDays']), chart['axisTicks']
  end

  test 'the hourly switch shows the last 5 days of hourly bars and switches back' do
    visit_chart
    daily_bars = chart_state['values'].size

    toggle_graph

    chart = chart_state

    assert_equal HOURLY_BARS, chart['values'].size
    assert_equal 'Rain per hour (inches)', chart['legend']
    assert_match(/one hour, over the last 5 days/, description_text)
    assert_axis_dates_plain(chart, 'hourly')
    # Five days of dates, under a week, so each keeps its month
    assert_equal 5, chart['axisTicks'].size
    assert(chart['axisTicks'].all? { |label| label.start_with?('Sep ') }, chart['axisTicks'].inspect)
    # The last bar is the latest reading, the first is 119 hours before it.
    assert_equal iso_hours_before(LAST_READING, 0), chart['hourlyTimes'].last
    assert_equal iso_hours_before(LAST_READING, HOURLY_BARS - 1), chart['hourlyTimes'].first

    toggle_graph

    assert_equal daily_bars, chart_state['values'].size
    assert_equal 'Rain per day (inches)', chart_state['legend']
  end

  test 'the last 24, 48 and 72 hours are shaded behind the bars, darkest most recent' do
    visit_chart

    assert_rain_windows('daily', slots_per_band: 1)
    assert_match(/Shading marks the last 24, 48 and 72 hours/, description_text)

    toggle_graph

    assert_rain_windows('hourly', slots_per_band: 24)
    assert_match(/Shading marks the last 24, 48 and 72 hours/, description_text)
  end

  # The fixture never crosses a month, so this hands the chart ten days that do
  test 'a new month gets its name on the x-axis as well as each week' do
    visit_chart

    labels = page.evaluate_script(<<~JS)
      (() => {
        const controller = #{CONTROLLER_JS};
        controller.timeSeriesDailyData = Array.from({ length: 10 }, (_, i) =>
          ({ label: new Date(2024, 8, 26 + i, 12), value: 0 }));
        controller.dailyDaysShown = null;
        controller.showGraphMode(false);
        return controller.timeSeriesChart.scales.x.ticks.map(tick => tick.label);
      })()
    JS

    assert_equal ['Sep 26', '27', '28', '29', '30', 'Oct 1', '2', 'Oct 3', '4', '5'], labels
  end

  test 'bars keep headroom below the shading labels, with no horizontal gridlines' do
    visit_chart

    assert_headroom('daily')

    toggle_graph

    assert_headroom('hourly')
  end

  test 'a phone shows fewer days, each wide enough for its label' do
    emulate_phone
    visit_chart

    state = chart_state
    all_days = state['dailyDays'].size

    assert_operator state['values'].size, :<, all_days, 'the phone still squeezes in every day'
    assert_operator state['values'].size, :>=, 4, 'too few days for the shaded 72 hours and today'
    # The most recent days, ending today
    assert_equal state['dailyDays'].last(state['values'].size), state['shownDays']
    assert_equal WINDOW_LABELS, state['labels'].pluck('text'), 'a shading label was left out'
    assert_equal expected_axis_labels(state['shownDays']), state['axisTicks']

    toggle_graph
    toggle_graph

    assert_equal state['values'].size, chart_state['values'].size,
                 'switching back to daily lost the fitted number of days'
  end

  test 'bars never overlap or sit on a gridline on a phone-width screen' do
    emulate_phone
    visit_chart

    assert_bars_clear('daily')
    assert_equal chart_state['bars'].size + 1, chart_state['gridLines'].size,
                 'the daily chart needs a gridline on every day boundary'

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
  # entry animation happens to have got to. Drawing once first fills in what
  # the shading plugin drew (chart.$rainWindowsDrawn) without waiting for the
  # browser's next frame.
  def chart_state
    page.evaluate_script(<<~JS)
      (() => {
        const controller = #{CONTROLLER_JS};
        const chart = controller.timeSeriesChart;
        chart.draw();
        const drawn = chart.$rainWindowsDrawn;
        const bars = chart.getDatasetMeta(0).data
          .map(bar => bar.getProps(['x', 'y', 'width'], true));
        const { left, right, top, bottom } = chart.chartArea;

        return {
          values: chart.data.datasets[0].data,
          legend: chart.data.datasets[0].label,
          // The x-axis labels Chart.js kept (it may skip some to fit)
          axisTicks: chart.scales.x.ticks.map(tick => tick.label).filter(Boolean),
          dailyDays: controller.timeSeriesDailyData.map(d => d.label.toDateString()),
          // Each bar's day (on the daily chart), from the time slot it covers
          shownDays: chart.$rainWindows.slots.map(slot => new Date(slot[0]).toDateString()),
          hourlyTimes: controller.timeSeriesHourlyData.map(d => d.label.toISOString()),
          chartWidth: chart.width,
          chartArea: { left, right, top, bottom },
          yMax: chart.scales.y.max,
          yGridShown: chart.options.scales.y.grid.display,
          bands: drawn.bands,
          labels: drawn.labels,
          gridLines: drawn.gridLines,
          bars
        };
      })()
    JS
  end

  # "Sep 20" or "20", never "Sep 20th"
  def assert_axis_dates_plain(state, mode)
    assert_not_empty state['axisTicks'], "#{mode}: no x-axis labels"
    state['axisTicks'].each do |label|
      assert_match(/\A([A-Z][a-z]{2} )?\d{1,2}\z/, label, "#{mode}: x-axis label #{label.inspect}")
    end
  end

  # For days given as toDateString()s: with more than a week of them, the
  # month once a week (from the first) and where a new month starts, else just
  # the day: "Sep 1", "2", ... "7", "Sep 8". A week or less: the month on each.
  def expected_axis_labels(days)
    dates = days.map { |day| Date.parse(day) }

    dates.each_with_index.map do |date, i|
      new_month = i.positive? && dates[i - 1].month != date.month
      if dates.size <= 7 || (i % 7).zero? || new_month
        date.strftime('%b %-d')
      else
        date.day.to_s
      end
    end
  end

  def assert_rain_windows(mode, slots_per_band:)
    state = chart_state
    bands = state['bands']
    area = state['chartArea']
    slot_width = (area['right'] - area['left']) / state['bars'].size

    assert_equal WINDOW_LABELS, bands.pluck('label'), "#{mode}: bands, newest first"
    assert_equal WINDOW_LABELS, state['labels'].pluck('text'), "#{mode}: each band is labelled"

    alphas = bands.pluck('alpha')

    assert_equal alphas.sort.reverse, alphas.uniq, "#{mode}: the newest band is the darkest"

    # Newest on the right, running to the edge; each older band touches the next
    assert_in_delta area['right'], bands[0]['right'], 0.01
    bands.each_cons(2) do |newer, older|
      assert_in_delta newer['left'], older['right'], 0.01, "#{mode}: #{older['label']} band leaves a gap"
    end

    # 24 hours of bar slots wide (the newest band also covers the rest of today)
    bands.drop(1).each do |band|
      assert_in_delta slots_per_band * slot_width, band['right'] - band['left'], 1,
                      "#{mode}: #{band['label']} band is not #{slots_per_band} bar slot(s) wide"
    end

    bands.each do |band|
      assert_in_delta area['top'], band['top'], 0.01
      assert_in_delta area['bottom'], band['bottom'], 0.01
    end
  end

  def assert_headroom(mode)
    state = chart_state
    tallest_bar_top = state['bars'].map { |bar| bar['y'] }.min
    lowest_label = state['labels'].map { |label| label['bottom'] }.max

    assert_operator state['yMax'], :>=, 1.2 * state['values'].max,
                    "#{mode}: the y-axis leaves no headroom above the tallest bar"
    assert_operator tallest_bar_top, :>, lowest_label,
                    "#{mode}: the tallest bar reaches the shading labels"
    assert_not state['yGridShown'], "#{mode}: horizontal gridlines are shown"
  end

  def assert_bars_clear(mode)
    state = chart_state

    assert_operator state['chartWidth'], :<=, PHONE_WIDTH,
                    'the chart did not shrink to the phone-width window'

    state['bars'].each_cons(2).with_index do |(left, right), index|
      gap = (right['x'] - (right['width'] / 2)) - (left['x'] + (left['width'] / 2))

      assert_operator gap, :>=, 0, "#{mode} bars #{index} and #{index + 1} overlap by #{-gap}px"
    end

    state['gridLines'].each do |line|
      bar = state['bars'].find { |b| (line > b['x'] - (b['width'] / 2)) && (line < b['x'] + (b['width'] / 2)) }

      assert_nil bar, "#{mode}: a gridline at #{line}px runs through a bar"
    end

    state['labels'].each_with_index do |label, index|
      band = state['bands'][index]

      assert_operator label['left'], :>=, band['left'] - 0.5, "#{mode}: #{label['text']} label spills left"
      assert_operator label['right'], :<=, band['right'] + 0.5, "#{mode}: #{label['text']} label spills right"
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
