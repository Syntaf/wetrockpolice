require 'test_helper'
require 'json'

class RafflesControllerTest < ActionDispatch::IntegrationTest
  include RaffleEntrySubmission

  VALID_ORDER_ID = '1234FFF'
  INVALID_ORDER_ID = 'FFF321'

  setup do
    stub_request(
      :post,
      'https://api.sandbox.paypal.com/v1/oauth2/token'
    ).to_return(
      status: 200,
      body: { access_token: 'abcd' }.to_json,
      headers: { content_type: 'application/json' }
    )

    stub_request(
      :get,
      "https://api.sandbox.paypal.com/v2/checkout/orders/#{VALID_ORDER_ID}"
    )

    stub_request(
      :get,
      "https://api.sandbox.paypal.com/v2/checkout/orders/#{INVALID_ORDER_ID}"
    ).to_return(
      status: 404,
      body: { name: 'RESOURCE_NOT_FOUND' }.to_json,
      headers: { content_type: 'application/json' }
    )
  end

  test 'Accepts card payment' do
    submit_raffle_entry(raffle_entries(:valid_entry))

    assert_response :created
  end

  test 'Validates raffle entry' do
    entry = raffle_entries(:valid_entry)

    validate_raffle_entry(entry)

    assert_response :success
  end

  test 'Rejects invalid raffle entry' do
    entry = raffle_entries(:valid_entry)
    entry.contact = nil

    validate_raffle_entry(entry)

    assert_response :bad_request
  end

  test 'Rejects empty order id' do
    entry = raffle_entries(:valid_entry)
    entry.order_id = nil

    submit_raffle_entry(entry)

    assert_response :payment_required
  end
end
