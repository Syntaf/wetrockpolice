require_relative "boot"

# Explicit railtie requires instead of `rails/all`. The frameworks left out
# are the ones this app has never used: Action Cable, Action Mailbox,
# Action Text and Active Storage. Loading them cost boot time, pulled in
# config surface that had to be maintained through every defaults bump, and
# invited accidental coupling.
require "rails"

require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "active_job/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# From the Rails 8.0 upgrade defaults: cap regexp matching at 1s as ReDoS
# protection. This is a Ruby-global setting, not a framework default, so it
# lives here rather than dying with the deleted new_framework_defaults file.
Regexp.timeout = 1

module Wetrockpolice
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    # 8.0 covers to_time_preserves_timezone = :zone and
    # action_dispatch.strict_freshness = true, both proven suite-green
    # individually before this flip.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # No Redis, and nothing in the app calls Rails.cache today. :memory_store
    # is per-process, which is fine at this scale and keeps the runtime
    # dependency list at "Postgres".
    config.cache_store = :memory_store

    # Sidekiq is gone. The only background work left is the admin
    # notification mail, so in-process threads are enough. Set explicitly
    # rather than leaning on Active Job's default so the decision is
    # greppable. config/environments/test.rb overrides this with :test.
    config.active_job.queue_adapter = :async

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
