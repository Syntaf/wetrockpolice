# frozen_string_literal: true

require 'test_helper'

# Guards the auth gate on the Sidekiq::Web mount until Sidekiq is removed.
#
# The mount lives inside `authenticated :user do ... end`, so for an anonymous
# visitor the route simply does not exist. It does NOT redirect to sign-in:
# the request falls through to the `/:slug/:coalition_slug` microsite scope and
# 404s there. Either way Sidekiq's UI is unreachable unauthenticated, which is
# the property worth pinning.
class SidekiqWebAccessTest < ActionDispatch::IntegrationTest
  test 'anonymous visitors cannot reach the sidekiq web UI' do
    get '/admin/sidekiq'

    assert_response :not_found
    refute_match(/sidekiq/i, response.body)
  end

  test 'the sidekiq web UI is still mounted behind authentication' do
    mount = Rails.application.routes.routes.find do |route|
      route.path.spec.to_s.start_with?('/admin/sidekiq')
    end

    assert mount, 'Sidekiq::Web should be mounted at /admin/sidekiq'
    assert_equal 'Sidekiq::Web', mount.app.app.to_s
  end
end
