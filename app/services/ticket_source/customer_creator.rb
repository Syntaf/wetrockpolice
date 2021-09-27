# frozen_string_literal: true

require 'ticketsource/client'

module TicketSource
  class CustomerCreator < ApplicationService
    class CreateCustomerException < StandardError; end

    def initialize(membership)
      super()
      @membership = membership
      @client = client
    end

    def call
      @client.create_customer(@membership)

      true
    rescue RestClient::ExceptionWithResponse => e
      error_message = JSON.parse(e.response.body)

      raise CreateCustomerException, error_message
    end

    private

    def client
      TicketSourceHttpClient.new(ENV['TICKETSOURCE_SECRET'])
    end
  end
end
