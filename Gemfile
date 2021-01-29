# frozen_string_literal: true

source 'https://rubygems.org'
ruby '~> 2.6'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Application specific gems
gem 'bootstrap', '4.3.1'
gem 'cancancan', '~> 3.0'
gem 'devise'
gem 'dotenv-rails'
gem 'jquery-rails'
gem 'material-sass', '4.1.1'
gem 'meta-tags'
gem 'paypal-checkout-sdk'
gem 'pg'
gem 'rails_12factor', group: :production
gem 'rails_admin', '~> 2.0'
gem 'roadie-rails', '~> 2.1'
gem 'seed_dump'

# K8s health checking
gem 'rails-healthcheck'

# Use webpacker js bundler
gem 'webpacker'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.2'
# Use Puma as the app server
gem 'puma', '~> 4.3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use faster connection library for Redis
gem 'hiredis'
# Sidekiq for jobs
gem 'sidekiq'

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
  gem 'debase'
  gem 'rubocop'
  gem 'rubocop-minitest', require: false
  gem 'rubocop-rails', require: false
  gem 'ruby-debug-ide'
  gem 'solargraph'
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw ruby]
