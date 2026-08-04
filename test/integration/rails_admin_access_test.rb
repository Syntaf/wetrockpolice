# frozen_string_literal: true

require 'test_helper'

# Smoke test for the rails_admin engine mount. rails_admin is the whole admin
# UI and is the highest-risk dependency in the upgrade path, so "the dashboard
# renders for a super admin" is worth a test on every hop.
class RailsAdminAccessTest < ActionDispatch::IntegrationTest
  test 'super admin gets the dashboard' do
    sign_in users(:super_admin)

    get rails_admin_path

    assert_response :success
  end

  test 'anonymous visitors are sent to the sign-in page' do
    get rails_admin_path

    assert_redirected_to new_user_session_path
  end

  test '/admin redirects to the engine mount point' do
    get '/admin'

    assert_response :moved_permanently
    assert_redirected_to '/admin/manage'
  end

  test 'a signed-in non-admin is denied by cancancan' do
    sign_in users(:plain_user)

    assert_raises(CanCan::AccessDenied) { get rails_admin_path }
  end
end
