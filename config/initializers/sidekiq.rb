# frozen_string_literal: true

sidekiq_config = { url: ENV['JOB_WORKER_URL'] }

Sidekiq.configure_server do |config|
  config.redis = sidekiq_config
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end

if Rails.env.development? && ActiveModel::Type::Boolean.new.cast(ENV['SIDEKIQ_EAGER_MODE'])
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
end