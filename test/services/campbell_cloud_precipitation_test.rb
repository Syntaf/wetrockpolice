# frozen_string_literal: true

require 'test_helper'

# CampbellCloud is reshaped into Synoptic's response format so the chart JS
# never has to know which provider a gauge lives on. These tests pin the
# reshaping (hour buckets, units, gaps) and the API conversation (login,
# datastream lookup, datapoints window, token retry) against stubs.
class CampbellCloudPrecipitationTest < ActiveSupport::TestCase
  HOST = 'https://us-west-2.campbell-cloud.com'
  ORG = '4b170721-0e5f-4158-bbdc-3d9d0f4ab2f4'
  DATASTREAM = '01a19d88-5b07-7516-af38-d06dc0bd32dc'
  CUMULATIVE_DATASTREAM = '01a19d88-5b08-7250-bbb1-ddacab2ac823'
  RECORD_DATASTREAM = '01a19d88-5b06-7685-9368-8bee0581e01a'
  NOW = Time.utc(2026, 11, 7, 3, 10)
  HOUR = 3_600_000
  HALF_HOUR = 1_800_000

  ENV_KEYS = %w[CAMPBELL_CLOUD_ORGANIZATION_ID CAMPBELL_CLOUD_USERNAME
                CAMPBELL_CLOUD_PASSWORD CAMPBELL_CLOUD_HOST].freeze

  setup do
    @previous_env = ENV_KEYS.index_with { |key| ENV.fetch(key, nil) }
    ENV['CAMPBELL_CLOUD_ORGANIZATION_ID'] = ORG
    ENV['CAMPBELL_CLOUD_USERNAME'] = 'wrp-reader@example.com'
    ENV['CAMPBELL_CLOUD_PASSWORD'] = 'service-test-password'
    ENV.delete('CAMPBELL_CLOUD_HOST')

    @gauge = rain_gauges(:black_velvet)
  end

  teardown do
    @previous_env.each { |key, value| ENV[key] = value }
  end

  # --- HourlySeries ------------------------------------------------------

  test 'readings are summed into the hour that ends at or after their stamp' do
    base = Time.utc(2026, 11, 7, 2).to_i * 1000 # 02:00

    points = [
      { 'ts' => base + (HOUR / 2), 'value' => 0.01 }, # 02:30 -> hour ending 03:00
      { 'ts' => base + HOUR, 'value' => 0.02 },       # 03:00 -> hour ending 03:00
      { 'ts' => base + (HOUR * 3 / 2), 'value' => 0 } # 03:30 -> hour ending 04:00
    ]

    series = CampbellCloudPrecipitation::HourlySeries.build(points)

    assert_equal [['2026-11-07T03:00:00Z', 0.03], ['2026-11-07T04:00:00Z', 0.0]], series
  end

  test 'hours with no readings are nil, not zero, so gaps stay gaps' do
    base = Time.utc(2026, 11, 7, 0).to_i * 1000

    points = [
      { 'ts' => base, 'value' => 0.1 },
      { 'ts' => base + (HOUR * 3), 'value' => 0.2 }
    ]

    series = CampbellCloudPrecipitation::HourlySeries.build(points)

    assert_equal [0.1, nil, nil, 0.2], series.map(&:last)
  end

  test 'millimetres are converted to inches' do
    series = CampbellCloudPrecipitation::HourlySeries.build(
      [{ 'ts' => Time.utc(2026, 11, 7, 1).to_i * 1000, 'value' => 25.4 }], units: 'mm'
    )

    assert_equal [['2026-11-07T01:00:00Z', 1.0]], series
  end

  test 'NAN, negative and missing readings are dropped' do
    ts = Time.utc(2026, 11, 7, 1).to_i * 1000

    points = [
      { 'ts' => ts, 'value' => 'NAN' },
      { 'ts' => ts, 'value' => -7999 },
      { 'ts' => ts, 'value' => nil },
      { 'ts' => nil, 'value' => 0.5 }
    ]

    series = CampbellCloudPrecipitation::HourlySeries.build(points)

    assert_empty series
  end

  # --- Cumulative ---------------------------------------------------------

  test 'running totals become per-reading increments, like the interval field' do
    base = Time.utc(2026, 11, 7, 2).to_i * 1000
    totals = [0.0, 0.01, 0.03, 0.03].each_with_index.map do |total, i|
      { 'ts' => base + (i * HALF_HOUR), 'value' => total }
    end

    increments = CampbellCloudPrecipitation::Cumulative.to_intervals(totals)

    # The first reading has nothing to diff against, so it's dropped.
    assert_equal [base + HALF_HOUR, base + (2 * HALF_HOUR), base + (3 * HALF_HOUR)], increments.pluck('ts')
    assert_equal [0.01, 0.02, 0.0], rounded_values(increments)
  end

  test 'rain that fell during a gap lands on the first reading after it' do
    base = Time.utc(2026, 11, 7, 2).to_i * 1000
    totals = [
      { 'ts' => base, 'value' => 0.1 },
      # 02:30, 03:00 and 03:30 never uploaded
      { 'ts' => base + (4 * HALF_HOUR), 'value' => 0.3 }
    ]

    increments = CampbellCloudPrecipitation::Cumulative.to_intervals(totals)

    assert_equal [base + (4 * HALF_HOUR)], increments.pluck('ts')
    assert_equal [0.2], rounded_values(increments)
  end

  test 'the API returns newest first; increments are still taken oldest to newest' do
    base = Time.utc(2026, 11, 7, 2).to_i * 1000
    totals = [{ 'ts' => base + HALF_HOUR, 'value' => 0.25 }, { 'ts' => base, 'value' => 0.05 }]

    assert_equal [0.2], rounded_values(CampbellCloudPrecipitation::Cumulative.to_intervals(totals))
  end

  test 'a logger restart counts the new total as rain since the restart' do
    base = Time.utc(2026, 11, 7, 2).to_i * 1000
    totals = [{ 'ts' => base, 'value' => 0.77 }, { 'ts' => base + HALF_HOUR, 'value' => 0.02 }]

    assert_equal [0.02], CampbellCloudPrecipitation::Cumulative.to_intervals(totals).pluck('value')
  end

  test 'a record number reset is a restart even when the new total is higher' do
    base = Time.utc(2026, 11, 7, 2).to_i * 1000
    totals = [{ 'ts' => base, 'value' => 0.01 }, { 'ts' => base + HALF_HOUR, 'value' => 0.05 }]
    records = [{ 'ts' => base, 'value' => 9792 }, { 'ts' => base + HALF_HOUR, 'value' => 0 }]

    # Without the record numbers this would be 0.04.
    assert_equal [0.05], CampbellCloudPrecipitation::Cumulative.to_intervals(totals, records).pluck('value')
  end

  test 'float noise in an unchanged total is zero rain, not a restart' do
    base = Time.utc(2026, 11, 7, 2).to_i * 1000
    totals = [{ 'ts' => base, 'value' => 0.770625 }, { 'ts' => base + HALF_HOUR, 'value' => 0.770625 - 1e-12 }]

    assert_equal [0.0], CampbellCloudPrecipitation::Cumulative.to_intervals(totals).pluck('value')
  end

  test 'unreadable totals are skipped, so the next good reading covers them' do
    base = Time.utc(2026, 11, 7, 2).to_i * 1000
    totals = [
      { 'ts' => base, 'value' => 0.1 },
      { 'ts' => base + HALF_HOUR, 'value' => 'NAN' },
      { 'ts' => base + (2 * HALF_HOUR), 'value' => 0.3 }
    ]

    increments = CampbellCloudPrecipitation::Cumulative.to_intervals(totals)

    assert_equal [base + (2 * HALF_HOUR)], increments.pluck('ts')
    assert_in_delta 0.2, increments.first['value']
  end

  # --- API conversation ---------------------------------------------------

  test 'returns Synoptic-shaped JSON for the configured table and field' do
    token = stub_token
    lookup = stub_datastreams
    points = stub_datapoints(data: [
                               { ts: ms(Time.utc(2026, 11, 7, 1, 30)), value: 0.0 },
                               { ts: ms(Time.utc(2026, 11, 7, 2)), value: 0.04 },
                               { ts: ms(Time.utc(2026, 11, 7, 2, 30)), value: 0.01 },
                               { ts: ms(Time.utc(2026, 11, 7, 3)), value: 0.0 }
                             ])

    # A real cache, so the token is reused across the two GETs (test env is :null_store).
    body = Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
      JSON.parse(CampbellCloudPrecipitation.new(@gauge, now: NOW).call)
    end

    assert_equal 1, body.dig('SUMMARY', 'RESPONSE_CODE')
    observations = body.dig('STATION', 0, 'OBSERVATIONS')
    assert_equal %w[2026-11-07T02:00:00Z 2026-11-07T03:00:00Z], observations['date_time']
    assert_equal [0.04, 0.01], observations['precip_intervals_set_1d']
    assert_equal 'black-velvet', body.dig('STATION', 0, 'STID')

    assert_requested token
    assert_requested lookup
    assert_requested points
  end

  test 'a cumulative gauge reads the running total and record number, crediting gap rain' do
    @gauge.update!(campbell_field: 'cum_ppt_in', cumulative: true)
    stub_token
    stub_datastreams
    totals = stub_datapoints(id: CUMULATIVE_DATASTREAM, data: [
                               { ts: ms(Time.utc(2026, 11, 7, 1)), value: 0.5 },
                               { ts: ms(Time.utc(2026, 11, 7, 1, 30)), value: 0.5 },
                               # 02:00 and 02:30 missing: 0.12 fell in there somewhere
                               { ts: ms(Time.utc(2026, 11, 7, 3)), value: 0.62 }
                             ])
    records = stub_datapoints(id: RECORD_DATASTREAM, data: [
                                { ts: ms(Time.utc(2026, 11, 7, 1)), value: 10 },
                                { ts: ms(Time.utc(2026, 11, 7, 1, 30)), value: 11 },
                                { ts: ms(Time.utc(2026, 11, 7, 3)), value: 14 }
                              ])

    body = JSON.parse(CampbellCloudPrecipitation.new(@gauge, now: NOW).call)

    observations = body.dig('STATION', 0, 'OBSERVATIONS')
    assert_equal %w[2026-11-07T02:00:00Z 2026-11-07T03:00:00Z], observations['date_time']
    # 02:00's hour has only the 01:30 reading (no rain); the gap's rain is
    # all credited to the hour ending 03:00.
    assert_equal [0.0, 0.12], observations['precip_intervals_set_1d']
    assert_requested totals
    assert_requested records
  end

  test 'asks for the last 20 days, in milliseconds, at the API maximum page size' do
    stub_token
    stub_datastreams
    stub_datapoints(data: [{ ts: ms(NOW), value: 0 }])

    CampbellCloudPrecipitation.new(@gauge, now: NOW).call

    assert_requested(:get, "#{HOST}/api/v1/organizations/#{ORG}/datastreams/#{DATASTREAM}/datapoints",
                     query: {
                       'startEpoch' => ms(NOW - 20.days).to_s,
                       'endEpoch' => ms(NOW).to_s,
                       'limit' => '15000',
                       'brief' => 'true'
                     })
  end

  test 'a 401 drops the token and retries once with a fresh one' do
    token = stub_token
    stub_datastreams
    stub_request(:get, "#{HOST}/api/v1/organizations/#{ORG}/datastreams/#{DATASTREAM}/datapoints")
      .with(query: hash_including({}))
      .to_return({ status: 401, body: '{}' },
                 { status: 200, body: { data: [{ ts: ms(NOW), value: 0.1 }] }.to_json })

    Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
      CampbellCloudPrecipitation.new(@gauge, now: NOW).call
    end

    assert_requested token, times: 2
  end

  test 'a missing datastream is an error, not an empty chart' do
    stub_token
    stub_request(:get, "#{HOST}/api/v1/organizations/#{ORG}/datastreams")
      .with(query: hash_including('stationId' => @gauge.station))
      .to_return(status: 200, body: [datastream('Rain_10min', 'Rain_mm_Tot', 'other-id')].to_json)

    error = assert_raises(CampbellCloudPrecipitation::Error) do
      CampbellCloudPrecipitation.new(@gauge, now: NOW).call
    end
    assert_includes error.message, 'Rain_30min.Rain_in_Tot'
  end

  test 'bad credentials never leak the password into the error' do
    stub_request(:post, "#{HOST}/api/v1/tokens").to_return(status: 401, body: '{"error":"invalid_grant"}')

    error = assert_raises(CampbellCloudPrecipitation::Error) do
      CampbellCloudPrecipitation.new(@gauge, now: NOW).call
    end
    assert_not_includes error.message, 'service-test-password'
  end

  test 'refuses to run without credentials' do
    ENV.delete('CAMPBELL_CLOUD_PASSWORD')

    assert_not CampbellCloudPrecipitation.configured?
    assert_raises(CampbellCloudPrecipitation::NotConfigured) do
      CampbellCloudPrecipitation.new(@gauge, now: NOW).call
    end
  end

  private

  # Differences of float totals (0.03 - 0.01) carry float noise.
  def rounded_values(increments)
    increments.map { |point| point['value'].round(6) }
  end

  def ms(time)
    (time.to_f * 1000).to_i
  end

  def stub_token
    stub_request(:post, "#{HOST}/api/v1/tokens")
      .with(body: {
              username: 'wrp-reader@example.com',
              password: 'service-test-password',
              client_id: 'cloud',
              grant_type: 'password'
            })
      .to_return(status: 200,
                 body: { access_token: 'bearer-abc', expires_in: 3600,
                         refresh_token: 'r', refresh_expires_in: 1800 }.to_json)
  end

  def stub_datastreams
    stub_request(:get, "#{HOST}/api/v1/organizations/#{ORG}/datastreams")
      .with(query: { 'stationId' => @gauge.station, 'limit' => '250' },
            headers: { 'Authorization' => 'Bearer bearer-abc' })
      .to_return(status: 200, body: [
        datastream('Rain_10min', 'Rain_mm_Tot', '01a0eeba-8d0d-7225-a114-e8e1241593cf'),
        datastream('Rain_30min', 'record', RECORD_DATASTREAM),
        datastream('Rain_30min', 'cum_ppt_in', CUMULATIVE_DATASTREAM),
        datastream('Rain_30min', 'Rain_in_Tot', DATASTREAM)
      ].to_json)
  end

  def stub_datapoints(data:, id: DATASTREAM)
    stub_request(:get, "#{HOST}/api/v1/organizations/#{ORG}/datastreams/#{id}/datapoints")
      .with(query: hash_including({}), headers: { 'Authorization' => 'Bearer bearer-abc' })
      .to_return(status: 200, body: { data: data, range: { exceeded_request: false } }.to_json)
  end

  def datastream(table, field, id)
    { id: id, profile: 'DATASTREAM', metadata: { '$profile': 'datastream', table: table, field: field } }
  end
end
