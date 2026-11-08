# frozen_string_literal: true

require 'test_helper'

class RainGaugeReportTest < ActiveSupport::TestCase
  NOW = Time.utc(2026, 11, 8, 12, 20)

  def body(hours)
    JSON.generate('STATION' => [{ 'OBSERVATIONS' => {
                    'date_time' => hours.map { |time, _| time.iso8601 },
                    'precip_intervals_set_1d' => hours.map { |_, value| value }
                  } }])
  end

  test 'summarizes last rain, time since rain and rolling totals' do
    hours = [
      [NOW - 8.days, 1.0],      # outside every window
      [NOW - 50.hours, 0.25],   # in 72h and 7d
      [NOW - 5.hours - 20.minutes, 0.1], # in all three
      [NOW - 2.hours - 20.minutes, 0.0]
    ]

    report = RainGaugeReport.new(rain_gauges(:black_velvet), body(hours), now: NOW).as_json

    assert_equal 'black-velvet', report[:id]
    assert_equal 'ok', report[:status]
    assert_equal (NOW - 5.hours - 20.minutes).iso8601, report[:last_rain_at]
    assert_equal 5, report[:hours_since_rain]
    assert_equal({ '24h' => 0.1, '72h' => 0.35, '7d' => 0.35 }, report[:totals])
    assert_equal 4, report[:hourly].size
  end

  test 'hours with no data stay null, and never count as rain' do
    hours = [[NOW - 2.hours, nil], [NOW - 1.hour, 0.0]]

    report = RainGaugeReport.new(rain_gauges(:black_velvet), body(hours), now: NOW).as_json

    assert_equal [nil, 0.0], report[:hourly].pluck(:precip)
    assert_nil report[:last_rain_at]
    assert_nil report[:hours_since_rain]
    assert_in_delta 0.0, report[:totals]['24h']
  end

  test 'an unavailable gauge is still listed, with no data' do
    report = RainGaugeReport.unavailable(rain_gauges(:black_velvet))

    assert_equal 'unavailable', report[:status]
    assert_empty report[:hourly]
  end
end
