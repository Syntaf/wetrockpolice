# frozen_string_literal: true

require 'test_helper'

# Phase 0 pinned the auth gate on the Sidekiq::Web mount at /admin/sidekiq.
# Phase 1 removed Sidekiq entirely, so this test now pins the absence: the
# path must be unroutable for everyone, signed in or not, and no route may
# quietly reclaim it.
#
# The request raises rather than rendering a 404 body because the test
# environment sets `show_exceptions = :none`; in production the same
# unrecognized path is rendered as 404 by the exception middleware.
class AdminSidekiqGoneTest < ActionDispatch::IntegrationTest
  test 'nothing is mounted under /admin/sidekiq' do
    mount = Rails.application.routes.routes.find do |route|
      route.path.spec.to_s.start_with?('/admin/sidekiq')
    end

    assert_nil mount, 'Sidekiq::Web should no longer be mounted'
  end

  test 'anonymous visitors cannot reach the sidekiq web UI' do
    assert_raises(ActionController::RoutingError) { get '/admin/sidekiq' }
  end

  test 'a signed-in super admin cannot reach the sidekiq web UI either' do
    sign_in users(:super_admin)

    assert_raises(ActionController::RoutingError) { get '/admin/sidekiq' }
  end
end
