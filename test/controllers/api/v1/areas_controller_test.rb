# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class AreasControllerTest < ActionDispatch::IntegrationTest
      KEY = 'wrp_test_partner_key'
      BODY = JSON.generate('STATION' => [{ 'OBSERVATIONS' => {
                             'date_time' => ['2026-11-08T11:00:00Z', '2026-11-08T12:00:00Z'],
                             'precip_intervals_set_1d' => [0.12, nil]
                           } }])

      setup { BaseController::RATE_LIMIT_STORE.clear }

      def get_api(path, key: KEY)
        get path, headers: key ? { 'Authorization' => "Bearer #{key}" } : {}
      end

      def with_gauge_data(body, &block)
        CampbellCloudPrecipitation.stub(:configured?, true) do
          CampbellCloudPrecipitation.stub(:cached, body, &block)
        end
      end

      test 'requests without a valid, active key are refused' do
        get_api '/api/v1/areas', key: nil
        assert_response :unauthorized
        assert_match(/Bearer/, response.headers['WWW-Authenticate'])

        get_api '/api/v1/areas', key: 'wrp_not_a_real_key'
        assert_response :unauthorized

        get_api '/api/v1/areas', key: 'wrp_revoked_key'
        assert_response :unauthorized
      end

      test 'lists only areas with shareable gauges, and only those gauges' do
        get_api '/api/v1/areas'

        assert_response :success
        areas = response.parsed_body['areas']
        assert_equal ['redrock'], areas.pluck('slug')
        assert_equal [{ 'id' => 'black-velvet', 'name' => 'Black Velvet' }], areas.first['gauges']
        assert_not_nil api_keys(:partner).reload.last_used_at
      end

      test 'an area returns its shareable gauges with hourly data, never the Synoptic primary' do
        with_gauge_data(BODY) do
          travel_to Time.utc(2026, 11, 8, 12, 30) do
            get_api '/api/v1/areas/redrock'
          end
        end

        assert_response :success
        body = response.parsed_body
        assert_equal 'in', body['units']
        assert_equal ['black-velvet'], body['gauges'].pluck('id')
        gauge = body['gauges'].first
        assert_equal 'ok', gauge['status']
        assert_equal '2026-11-08T11:00:00Z', gauge['last_rain_at']
        assert_equal 1, gauge['hours_since_rain']
        assert_equal [0.12, nil], gauge['hourly'].pluck('precip')
        assert_not_includes response.body, 'RRKN2'
      end

      test 'a failing provider is reported per gauge, not as an error' do
        with_gauge_data(nil) { get_api '/api/v1/areas/redrock' }

        assert_response :success
        assert_equal 'unavailable', response.parsed_body['gauges'].first['status']
      end

      test 'areas without shareable gauges, and unknown areas, are 404' do
        get_api '/api/v1/areas/castlerock'
        assert_response :not_found

        get_api '/api/v1/areas/nowhere'
        assert_response :not_found
      end

      test 'each key is rate limited' do
        BaseController::RATE_LIMIT.times { get_api '/api/v1/areas' }
        assert_response :success

        get_api '/api/v1/areas'
        assert_response :too_many_requests
      end
    end
  end
end
