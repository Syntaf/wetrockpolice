require 'test_helper'

class CashValidationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get cash_validations_index_url
    assert_response :success
  end

  test "should get confirm" do
    get cash_validations_confirm_url
    assert_response :success
  end

  test "should get deny" do
    get cash_validations_deny_url
    assert_response :success
  end

end
