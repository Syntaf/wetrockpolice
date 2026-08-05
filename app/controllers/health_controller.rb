# frozen_string_literal: true

# Readiness endpoint for the k8s readinessProbe. Liveness (/up) is Rails'
# built-in rails/health#show and deliberately never touches the database;
# readiness must, because a pod that cannot reach Postgres should be pulled
# out of the Service until it can answer real requests again.
class HealthController < ApplicationController
  def ready
    ActiveRecord::Base.connection.execute('SELECT 1')
    head :ok
  rescue ActiveRecord::ActiveRecordError, PG::Error
    head :service_unavailable
  end
end
