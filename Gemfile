# frozen_string_literal: true

source 'https://rubygems.org'

# Single source of truth for the interpreter version: .ruby-version drives
# rvm locally, ruby/setup-ruby in CI, and this directive, so they cannot drift
# (the lockfile recorded 3.1.4 while .ruby-version pinned 3.1.7).
ruby file: '.ruby-version'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Authorization & Authentication
gem 'cancancan', '~> 3.6'
gem 'devise', '~> 5.0'
# Environment management
gem 'dotenv-rails'
# SEO
gem 'meta-tags', '~> 2.21'
# Postgres client
gem 'pg'
# Administrative backend. 3.3 serves its own assets via importmap-rails +
# Propshaft (`config.asset_source = :importmap`), engine-isolated from the
# app's bundle — no rails_admin npm package, no app-side pack.
gem 'rails_admin', '~> 3.3.0'
# rails_admin's importmap asset mode: importmap-rails resolves the engine's
# pinned modules, Propshaft digests/serves them — and Propshaft also serves
# the app's own esbuild/sass output from app/assets/builds.
gem 'importmap-rails'
gem 'propshaft'
# Builds the app's stylesheet and rails_admin's stylesheet (dart-sass) into
# app/assets/builds for Propshaft, and hooks the build into
# assets:precompile and test:prepare.
gem 'cssbundling-rails'
# Bundles app/javascript/application.js with esbuild into app/assets/builds
# for Propshaft (tree-shaken, minified single bundle), and hooks the build
# into assets:precompile and test:prepare.
gem 'jsbundling-rails'
# Turbo as a first-class dependency (was only ever transitive via
# rails_admin). rails_admin 3.3 allows turbo-rails < 3; the app adopts Turbo
# properly in the next step of Phase 2.
gem 'turbo-rails', '~> 2.0'
# Rails framework — pinned to the 8.1 series (current stable); series bumps
# are deliberate, separately-tested steps, not something `bundle update` may do.
gem 'rails', '~> 8.1.0'
# Use Puma as the app server. 7.x tightened the default bind to localhost,
# so config/puma.rb binds 0.0.0.0 explicitly for the k8s pods.
gem 'puma', '~> 7.2'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :development, :test do
  # Adds support for Capybara system testing and selenium driver.
  # 3.40 is the current series; 2.18 was a 2018 release that predates the
  # W3C-WebDriver-only selenium 4 API. selenium 4.x resolves its own
  # driver binary through selenium-manager, so no webdrivers gem is needed.
  gem 'capybara', '~> 3.40'
  gem 'selenium-webdriver', '~> 4.19'
  gem 'webmock'
end

group :test do
  # Test coverage baseline
  gem 'simplecov', require: false
end

group :development do
  # Access an IRB console on exception pages or by
  # using <%= console %> anywhere in the code.
  gem 'rubocop'
  gem 'rubocop-minitest', require: false
  gem 'rubocop-rails', require: false
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw ruby]
