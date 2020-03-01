# frozen_string_literal: true

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

module SnccApplication
  def submit_sncc_application(app)
    post redrock_new_sncc_membership_url, params: {
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
        paid_cash: app.paid_cash
      }
    }
  end
end
