# frozen_string_literal: true

require 'test_helper'

class WatchedAreaControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get watched_area_url :redrock
    assert_response :success
  end

  test 'renders the public 404 page for an unknown slug' do
    get watched_area_url :'no-such-area'

    assert_response :not_found
    assert_includes @response.body, 'may have moved'
  end
end
