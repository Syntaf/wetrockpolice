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
        response = @client.execute(request)
      rescue PayPalHttp::HttpError => e
        logger.info e
      end

      response
    end
  end
end