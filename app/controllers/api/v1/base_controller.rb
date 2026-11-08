# frozen_string_literal: true

module Api
  module V1
    # Partner rain data API. Server-to-server only: every request needs an
    # `Authorization: Bearer wrp_...` key (see ApiKey), and there's no CORS,
    # since a key used from a browser would be public.
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      RATE_LIMIT = 60
      # Per process, like the page's weather cache: with two pods a key gets
      # up to ~2x this. Enough to stop a runaway client without Redis.
      RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

      before_action :authenticate_api_key
      rate_limit to: RATE_LIMIT, within: 1.minute, by: -> { @api_key.id }, store: RATE_LIMIT_STORE,
                 with: -> { render json: { error: 'rate limit exceeded' }, status: :too_many_requests }

      private

      def authenticate_api_key
        @api_key = authenticate_with_http_token { |token, _options| ApiKey.authenticate(token) }
        return @api_key.record_use! if @api_key

        response.headers['WWW-Authenticate'] = 'Bearer realm="wetrockpolice"'
        render json: { error: 'missing or invalid API key' }, status: :unauthorized
      end
    end
  end
end
