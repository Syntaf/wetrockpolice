# frozen_string_literal: true

module RailsAdmin
  module Config
    module Actions
      class MarkDelivered < RailsAdmin::Config::Actions::Base
        register_instance_option :collection? do
          true
        end

        register_instance_option :bulkable? do
          true
        end

        register_instance_option :http_methods do
          [:post]
        end
      end
    end
  end
end
