# frozen_string_literal: true

module PayPalPayments
  class OrderValidator < ApplicationService
    include PayPalCheckoutSdk::Orders

    def initialize(order_id)
      @order_id = order_id
      @client = client
    end

    def call
      return false if @order_id.blank?

      request = OrdersGetRequest.new(@order_id)
      @client.execute(request)

      true
    rescue PayPalHttp::HttpError => e
      Rails.logger.info e.result
      Rails.logger.info e.status_code
      false
    end

    private

    def client
      PayPal::PayPalHttpClient.new(
        if Rails.env.development? || Rails.env.test?
          PayPal::SandboxEnvironment.new(
            ENV['PAYPAL_CLIENT_ID'],
            ENV['PAYPAL_CLIENT_SECRET']
          )
        else
          PayPal::LiveEnvironment.new(
            ENV['PAYPAL_CLIENT_ID'],
            ENV['PAYPAL_CLIENT_SECRET']
          )
        end
      )
    end
  end
end
