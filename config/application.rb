require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Wetrockpolice
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # No Redis, and nothing in the app calls Rails.cache today. :memory_store
    # is per-process, which is fine at this scale and keeps the runtime
    # dependency list at "Postgres".
    config.cache_store = :memory_store

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
