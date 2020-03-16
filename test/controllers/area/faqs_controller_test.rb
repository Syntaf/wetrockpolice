# frozen_string_literal: true

require 'test_helper'

class FaqsControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get watched_area_faqs_url :redrock
    assert_response :success
  end
end
