require 'test_helper'
require 'json'

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  include SnccApplication

  VALID_ORDER_ID = '1234FFF'.freeze
  INVALID_ORDER_ID = 'FFF321'.freeze

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

  test 'valid_order_submitted' do
    submit_sncc_application(joint_membership_applications(:valid_application))

    assert_response :redirect
    assert flash[:membership_successful]
  end

  test 'invalid_order_submitted' do
    app = joint_membership_applications(:valid_application)
    app.order_id = INVALID_ORDER_ID

    submit_sncc_application(app)

    assert_response :redirect
    assert_nil flash[:membership_successful]
    assert flash[:invalid_order]
  end

  test 'valid_cash_payment' do
    app = joint_membership_applications(:valid_application)
    app.order_id = nil
    app.paid_cash = true

    submit_sncc_application(app)

    assert_response :redirect
    assert flash[:membership_successful]
  end

  test 'invalid_cart_payment' do
    app = joint_membership_applications(:valid_application)
    app.order_id = null
    app.paid_cash = false

    submit_sncc_application(app)

    assert_response :redirect
    assert flash[:invalid_order]
  end
end
