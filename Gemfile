# frozen_string_literal: true

source 'https://rubygems.org'
ruby '~> 3.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Application specific gems
gem 'bootstrap', '~> 5.3.2'
gem 'jquery-rails'
gem 'material-sass', '4.1.1'
# Authorization & Authentication
gem 'cancancan', '~> 3.3.0'
gem 'devise', '~> 4.8.1'
# Environment management
gem 'dotenv-rails'
# SEO
gem 'meta-tags', '~> 2.20'
# Payment processing (deprecated)
gem 'paypal-checkout-sdk'
gem 'pg'
gem 'rails_12factor', group: :production
gem 'rails_admin', '~> 3.1'
gem 'rest-client', '~> 2.1.0'
# Dump data into seed file
gem 'seed_dump'

# K8s health checking
gem 'rails-healthcheck'

# Use webpacker js bundler
gem 'webpacker'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.1'
# Use Puma as the app server
gem 'puma', '~> 6.4'
# Use SCSS for stylesheets
gem 'sassc-rails', '~> 2.1'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use faster connection library for Redis
gem 'hiredis'
# Sidekiq for jobs
gem 'sidekiq', '~> 7.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :development, :test do
  # gem 'codecov', require: false

  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
  gem 'webmock'
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
