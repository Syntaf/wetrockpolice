# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren, Style/ExpandPathArguments

require 'simplecov'
SimpleCov.start 'rails'

require File.expand_path('../../config/environment', __FILE__)
require 'minitest/autorun'
require 'rails/test_help'
require 'sidekiq/testing'
require 'webmock/minitest'

Sidekiq::Testing.fake!

module SidekiqMinitestSupport
  def after_teardown
    Sidekiq::Worker.clear_all
    super
  end
end

class ActiveSupport::TestCase
  fixtures :all
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

# rubocop:enable Style/ClassAndModuleChildren, Style/ExpandPathArguments
