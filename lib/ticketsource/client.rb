# frozen_string_literal: true

require 'rest-client'

module TicketSource
  class TicketSourceHttpClient
    BASE_URL = 'https://api.ticketsource.io'

    def initialize(api_key)
      @api_key = api_key
    end

    def self.from_env
      Client.new(ENV['TICKETSOURCE_SECRET'])
    end

    def create_customer(membership)
      RestClient.post(
        "#{BASE_URL}/customers",
        {
          data: {
            type: 'customer',
            attributes: {
              first_name: membership.first_name,
              last_name: membership.last_name,
              membership: {
                identifier: membership.order_id
              }
            }
          }
        },
        headers
      )
    end

    private

    def headers
      { Authorization: "Bearer #{@api_key}" }
    end
  end
end
