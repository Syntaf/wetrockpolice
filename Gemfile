# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 3.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Authorization & Authentication
gem 'cancancan', '~> 3.3.0'
gem 'devise', '~> 4.9.3'
# Environment management
gem 'dotenv-rails'
# SEO
gem 'meta-tags', '~> 2.20'
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
# Rails framework — pinned to the 7.1 series; the upgrade to 7.2+ is a
# deliberate, separately-tested step, not something `bundle update` may do.
gem 'rails', '~> 7.1.6'
# Use Puma as the app server. The `>= 6.4.3` floor is the Phase 0 security
# patch; the move to Puma 7.x is a separate, deliberate step.
gem 'puma', '~> 6.4', '>= 6.4.3'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :development, :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
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
