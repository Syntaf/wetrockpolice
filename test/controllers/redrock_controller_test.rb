# frozen_string_literal: true

require 'test_helper'

class RedrockControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get redrock_index_url
    assert_response :success
  end
end
