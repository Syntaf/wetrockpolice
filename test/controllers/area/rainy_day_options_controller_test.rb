# frozen_string_literal: true

require 'test_helper'

class RainyDayOptionsControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get watched_area_rainy_day_options_url :redrock
    assert_response :success
  end
end
