# frozen_string_literal: true

require 'test_helper'

class RainyDayOptionsControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get watched_area_rainy_day_options_url :redrock
    assert_response :success
  end

  test 'gets area' do
    area = rainy_day_areas(:area1_redrock)

    get watched_area_rainy_day_option_url(
      area.watched_area.slug,
      area.climbing_area.id,
      format: :json
    )

    assert_response :success
    assert_equal area.to_json, @response.body
  end

  test 'renders JSON null when no rainy day area matches' do
    get watched_area_rainy_day_option_url(:redrock, -1, format: :json)

    assert_response :success
    assert_equal 'null', @response.body
  end

  test 'show rejects non-JSON formats' do
    area = rainy_day_areas(:area1_redrock)

    assert_raises(ActionController::UnknownFormat) do
      get watched_area_rainy_day_option_url(
        area.watched_area.slug,
        area.climbing_area.id
      )
    end
  end
end
