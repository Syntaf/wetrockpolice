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

  test 'confirm cash paid' do
    sign_in users(:super_admin)

    pending_application = joint_membership_applications(:pending_application)
    patch cash_url pending_application
    assert_response :success

    updated_membership = JointMembershipApplication.find(pending_application.id)
    assert_not updated_membership.pending
  end

  test 'deny cash paid' do
    sign_in users(:super_admin)

    pending_application = joint_membership_applications(:pending_application)
    delete cash_url pending_application
    assert_response :success

    assert_raises ActiveRecord::RecordNotFound do
      JointMembershipApplication.find(pending_application.id)
    end
  end
end
