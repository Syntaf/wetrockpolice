# frozen_string_literal: true

require 'test_helper'

class CashValidationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers

  # setup do
  #   get '/users/sign_in'
    
  #   post user_session_url
  # end

  test 'should get index' do
    login_as(FactoryBot.create(:user), :scope => :user)
    get cash_index_url
    assert_response :success
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
