# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren, Style/ExpandPathArguments

require 'simplecov'
SimpleCov.start 'rails'

require File.expand_path('../../config/environment', __FILE__)
require 'minitest/autorun'
require 'rails/test_help'
require 'webmock/minitest'

# System tests drive chromedriver and the in-process Capybara server over
# 127.0.0.1; webmock/minitest blocks every connection by default, which turns
# each browser command into a NetConnectNotAllowedError. Real external hosts
# stay blocked -- keeping accidental outbound calls out of the suite is the
# only reason webmock is a dependency here.
WebMock.disable_net_connect!(allow_localhost: true)

class ActiveSupport::TestCase
  fixtures :all
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

# rubocop:enable Style/ClassAndModuleChildren, Style/ExpandPathArguments
