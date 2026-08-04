# frozen_string_literal: true

require 'test_helper'

class UserSignInTest < ActionDispatch::IntegrationTest
  test 'valid credentials sign the user in and redirect to the admin backend' do
    post user_session_url, params: {
      user: { email: users(:super_admin).email, password: 'password' }
    }

    assert_redirected_to rails_admin_path
    # 303 (not 302) so Turbo Drive re-issues the follow-up as a GET.
    assert_equal 303, response.status

    follow_redirect!
    assert_response :success
  end

  # Regression test for the Devise/Turbo bug fixed by
  # config.responder.error_status = :unprocessable_entity. Before that,
  # a rejected sign-in re-rendered the form with a 200, which Turbo Drive
  # discards — the user saw no error at all.
  test 'invalid credentials re-render the sign-in form with 422' do
    post user_session_url, params: {
      user: { email: users(:super_admin).email, password: 'wrong-password' }
    }

    assert_equal 422, response.status,
                 'failed sign-in must be 422 or Turbo Drive drops the response'
    assert_select 'form[action=?]', user_session_path
    assert_nil request.env['warden'].user
  end

  test 'unknown email is rejected with 422' do
    post user_session_url, params: {
      user: { email: 'nobody@test.com', password: 'password' }
    }

    assert_equal 422, response.status
    assert_nil request.env['warden'].user
  end

  test 'an unapproved user cannot sign in' do
    post user_session_url, params: {
      user: { email: users(:unapproved_user).email, password: 'password' }
    }

    assert_redirected_to new_user_session_path
    assert_nil request.env['warden'].user
  end

  test 'an unconfirmed user cannot sign in' do
    post user_session_url, params: {
      user: { email: users(:unconfirmed_user).email, password: 'password' }
    }

    assert_redirected_to new_user_session_path
    assert_nil request.env['warden'].user
  end

  test 'signing out redirects to the root with 303' do
    sign_in users(:super_admin)

    delete destroy_user_session_url

    assert_equal 303, response.status
    assert_redirected_to root_path
    assert_nil request.env['warden'].user
  end
end
