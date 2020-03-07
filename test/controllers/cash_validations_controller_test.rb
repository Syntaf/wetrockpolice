# frozen_string_literal: true

require 'test_helper'

class CashValidationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get index' do
    sign_in users(:super_admin)
    get cash_index_url
    assert_response :success
  end

  test 'should redirect to login' do
    get cash_index_url
    assert_response :redirect
  end

  # test 'validate cash paid' do
  #   patch cash_url(1)
  #   assert_response :success
  # end

  # test 'remove membership application' do
  #   delete cash_url
  #   assert_response :success
  # end
end
