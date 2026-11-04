# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren, Style/ExpandPathArguments

require 'simplecov'
SimpleCov.start 'rails'

require File.expand_path('../../config/environment', __FILE__)
require 'minitest/autorun'
require 'rails/test_help'
require 'webmock/minitest'

class ActiveSupport::TestCase
  fixtures :all
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

# rubocop:enable Style/ClassAndModuleChildren, Style/ExpandPathArguments
