# frozen_string_literal: true

require 'test_helper'

class RainGaugeTest < ActiveSupport::TestCase
  test 'fixtures are valid' do
    assert rain_gauges(:black_velvet).valid?
    assert rain_gauges(:castlerock_backup).valid?
  end

  test 'gauges are listed under their watched area in position order' do
    assert_equal [rain_gauges(:black_velvet)], watched_areas(:redrock).rain_gauges.to_a
  end

  test 'campbell gauges need a station uuid and a table and field' do
    gauge = rain_gauges(:black_velvet)

    gauge.station = 'RRKN2'
    assert_not gauge.valid?
    assert gauge.errors.of_kind?(:station, :invalid)

    gauge.station = '01a0c4e4-b777-71d7-8106-6f6d83d0c84a'
    gauge.campbell_table = nil
    gauge.campbell_field = 'Rain_in_Tot; DROP'
    assert_not gauge.valid?
    assert gauge.errors.key?(:campbell_table)
    assert gauge.errors.key?(:campbell_field)
  end

  test 'synoptic gauges use the same station id shape as the weather proxy' do
    gauge = rain_gauges(:castlerock_backup)

    gauge.station = 'not a station!'
    assert_not gauge.valid?

    gauge.station = 'AV151'
    assert gauge.valid?
  end

  test 'slugs are url-safe and unique within an area' do
    gauge = rain_gauges(:black_velvet).dup

    assert_not gauge.valid?, 'duplicate slug in the same area'
    assert gauge.errors.of_kind?(:slug, :taken)

    gauge.slug = 'Black Velvet'
    assert_not gauge.valid?
    assert gauge.errors.of_kind?(:slug, :invalid)

    gauge.watched_area = watched_areas(:castlerock)
    gauge.slug = 'black-velvet'
    assert gauge.valid?, 'the same slug is fine in another area'
  end

  test 'provider and units are restricted to what the proxy understands' do
    gauge = rain_gauges(:black_velvet)

    gauge.provider = 'weatherunderground'
    gauge.units = 'cm'

    assert_not gauge.valid?
    assert gauge.errors.key?(:provider)
    assert gauge.errors.key?(:units)
  end
end
