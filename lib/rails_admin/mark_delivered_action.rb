# frozen_string_literal: true

module RailsAdmin
  module Config
    module Actions
      class MarkDelivered < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::MarkDelivered)

        register_instance_option :collection? do
          true
        end

        register_instance_option :bulkable? do
          true
        end

        register_instance_option :http_methods do
          [:post]
        end

        register_instance_option :controller do
          proc do
            list_entries(@model_config).update(delivered: true)

            flash[:notice] = 'Selected membership successfully marked as delivered'
            redirect_to index_path
          end
        end
      end
    end
  end
end
