# frozen_string_literal: true

require 'test_helper'

# /up is the k8s livenessProbe (Rails' built-in, DB-free by design) and
# /ready the readinessProbe (must prove the database answers). These pin
# both contracts, including readiness flipping to 503 when Postgres is
# unreachable -- the whole reason /ready exists apart from /up.
class HealthEndpointsTest < ActionDispatch::IntegrationTest
  test 'liveness endpoint /up returns 200' do
    get '/up'

    assert_response :ok
  end

  test 'readiness endpoint /ready returns 200 when the database answers' do
    get '/ready'

    assert_response :ok
  end

  test 'readiness endpoint /ready returns 503 when the database check raises' do
    db_down = -> { raise ActiveRecord::ConnectionNotEstablished, 'database is unreachable' }

    ActiveRecord::Base.stub(:connection, db_down) do
      get '/ready'
    end

    assert_response :service_unavailable
  end
end
