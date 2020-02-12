require 'test_helper'
require 'json'

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  include SnccApplication

  VALID_ORDER_ID = '1234FFF'

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
  end

  test 'valid_order_submitted' do
    submit_sncc_application(joint_membership_applications(:valid_application))

    assert_response :redirect
    assert flash[:membership_successful]
  end
end
