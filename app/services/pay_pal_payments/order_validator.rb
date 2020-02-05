# frozen_string_literal: true

module PayPalPayments
  class OrderValidator < ApplicationService
    include PayPalCheckoutSdk::Orders

    def initialize(order_id)
      @request = OrdersGetRequest.new(order_id)
      @client = client
    end

    def call
      @client.execute(@request)
      true
    rescue PayPalHttp::HttpError => e
      Rails.logger.info e.result
      Rails.logger.info e.status_code
      false
    end

    private

    def client
      PayPal::PayPalHttpClient.new(
        if Rails.env.development?
          PayPal::SandboxEnvironment.new(
            ENV['PAYPAL_CLIENT_ID'],
            ENV['PAYPAL_CLIENT_SECRET']
          )
        else
          PayPal::ProductionEnvironment.new(
            ENV['PAYPAL_CLIENT_ID'],
            ENV['PAYPAL_CLIENT_SECRET']
          )
        end
      )
    end
  end
end
