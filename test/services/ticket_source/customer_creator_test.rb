# frozen_string_literal: true

require 'test_helper'

module TicketSource
  class CustomerCreatorTest < ActiveSupport::TestCase
    setup do
      stub_request(
        :post,
        'https://api.ticketsource.io/customers'
      ).to_return(
        status: 201,
        body: { access_token: 'abcd' }.to_json,
        headers: { content_type: 'application/json' }
      )
    end

    test 'creates new customer' do
      membership = joint_membership_applications(:valid_application)

      TicketSource::CustomerCreator.call(membership)
    end
  end
end
