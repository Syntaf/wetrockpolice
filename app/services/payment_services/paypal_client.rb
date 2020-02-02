# frozen_string_literal: true

module PaymentServices
  class PaypalClient
    include PayPalCheckoutSdk::Orders

    def initialize
      @environment =
        if Rails.env.development?
          PayPal::SandboxEnvironment.new(
            ENV['PAYPAL_CLIENT_ID'],
            ENV['PAYPAL_CLIENT_SECRET'])
        else
          PayPal::ProductionEnvironment.new(
            ENV['PAYPAL_CLIENT_ID'],
            ENV['PAYPAL_CLIENT_SECRET'])
        end

      @client = PayPal::PayPalHttpClient.new(@environment)
    end

    def order_valid?(order_id)
      request = OrdersGetRequest.new(order_id)

      begin
        @client.execute(request)
      rescue PayPalHttp::HttpError => e
        Rails.logger.info e.result
        Rails.logger.info e.status_code

        return false
      end

      true
    end
  end
end
