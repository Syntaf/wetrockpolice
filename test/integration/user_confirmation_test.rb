# frozen_string_literal: true

require 'test_helper'

# Pins the Devise confirmation flow. `devise_for :users` declares no
# `controllers:` override, so /users/confirmation is served by
# Devise::ConfirmationsController. Phase 1 deleted the unreferenced
# app/controllers/confirmations_controller.rb on the strength of these
# assertions — its custom `after_confirmation_path_for` (which would have
# signed the user in and bounced admins to rails_admin) never ran, and the
# first test below keeps proving that nothing re-routes /users/confirmation
# away from Devise.
class UserConfirmationTest < ActionDispatch::IntegrationTest
  test 'the custom ConfirmationsController is not routed' do
    assert_equal 'devise/confirmations#show',
                 Rails.application.routes.recognize_path(
                   '/users/confirmation', method: :get
                 ).values_at(:controller, :action).join('#')
  end

  test 'a valid token confirms the account and redirects to sign-in' do
    user = users(:unconfirmed_user)
    assert_not user.confirmed?

    get user_confirmation_url(confirmation_token: user.confirmation_token)

    assert_redirected_to new_user_session_path
    assert user.reload.confirmed?
    assert_nil request.env['warden'].user,
               'confirmation does not sign the user in'
  end

  test 'an admin confirming lands on sign-in, not the admin backend' do
    user = users(:unconfirmed_user)
    # update_columns on purpose: promote the fixture without tripping
    # validations or the after_create_commit admin mail.
    user.update_columns(admin: true, super_admin: true) # rubocop:disable Rails/SkipsModelValidations

    get user_confirmation_url(confirmation_token: user.confirmation_token)

    assert_redirected_to new_user_session_path
    assert user.reload.confirmed?
  end

  test 'an invalid token re-renders the resend-confirmation form' do
    get user_confirmation_url(confirmation_token: 'not-a-real-token')

    assert_response :success
    assert_select 'form[action=?]', user_confirmation_path
    assert_not users(:unconfirmed_user).reload.confirmed?
  end

  test 'the resend-confirmation form is reachable' do
    get new_user_confirmation_url

    assert_response :success
    assert_select 'form[action=?]', user_confirmation_path
  end
end
