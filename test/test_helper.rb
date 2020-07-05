# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren, Style/ExpandPathArguments, Layout/LineLength

unless ENV['CODECOV_TOKEN'].nil?
  require 'simplecov'
  SimpleCov.start

  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'

class ActiveSupport::TestCase
  fixtures :all
end

module SnccApplication
  def submit_sncc_application(app)
    post watched_area_local_climbing_org_new_membership_url :redrock, :sncc, params: {
      joint_membership_application: {
        first_name: app.first_name,
        last_name: app.last_name,
        email: app.email,
        phone_number: app.phone_number,
        street_line_one: app.street_line_one,
        street_line_two: app.street_line_two,
        city: app.city,
        state: app.state,
        zipcode: app.zipcode,
        amount_paid: app.amount_paid,
        organization: app.organization,
        shirt_size: app.shirt_size,
        order_id: app.order_id,
        local_shirt: app.local_shirt,
        access_fund_shirt: app.access_fund_shirt,
        paid_cash: app.paid_cash,
        delivery_method: app.delivery_method
      }
    }
  end

  def validate_sncc_application(app)
    post watched_area_local_climbing_org_validate_url :redrock, :sncc, params: {
      joint_membership_application: {
        first_name: app.first_name,
        last_name: app.last_name,
        email: app.email,
        phone_number: app.phone_number,
        street_line_one: app.street_line_one,
        street_line_two: app.street_line_two,
        city: app.city,
        state: app.state,
        zipcode: app.zipcode,
        amount_paid: app.amount_paid,
        organization: app.organization,
        shirt_size: app.shirt_size,
        order_id: app.order_id,
        local_shirt: app.local_shirt,
        access_fund_shirt: app.access_fund_shirt,
        paid_cash: app.paid_cash,
        delivery_method: app.delivery_method
      }
    }
  end
end

# rubocop:enable Style/ClassAndModuleChildren, Style/ExpandPathArguments, Layout/LineLength
