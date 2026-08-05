require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Mail goes out through SendGrid SMTP; only the password comes from the
  # environment.
  config.action_mailer.default_url_options = { host: "wetrockpolice.com" }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default charset: "utf-8"
  config.action_mailer.asset_host = "https://wetrockpolice.com"
  config.action_mailer.smtp_settings = {
    address:                "smtp.sendgrid.net",
    port:                   587,
    domain:                 "wetrockpolice.com",
    user_name:              "apikey",
    password:               ENV["SENDGRID_PASSWORD"],
    authentication:         :plain,
    enable_starttls_auto:   true
  }

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # The Rails app serves its own (Propshaft-digested) assets: nothing sits in
  # front of it but the ingress. The k8s deployment sets
  # RAILS_SERVE_STATIC_FILES; far-future caching is safe on digested paths.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # TLS terminates at the nginx ingress, so every request reaching the pod is
  # plain HTTP: assume_ssl makes Rails treat them as HTTPS (no redirect loop
  # behind the terminating proxy), while force_ssl adds
  # Strict-Transport-Security and marks cookies Secure. Because assume_ssl
  # applies to every request — including the kubelet's plain-HTTP probes of
  # /up and /ready — the SSL middleware never redirects them, so no
  # ssl_options exclusion is needed.
  config.assume_ssl = true
  config.force_ssl = true

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # :info, not :debug — logs go to stdout for cluster-level aggregation and
  # debug-level output leaks full SQL and params into them.
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
