# frozen_string_literal: true

module TicketSource
  class SyncMembershipWorker
    include Sidekiq::Worker

    sidekiq_options retry: 3
    sidekiq_retry_in do |count, _exception|
      60 * count
    end

    def perform(membership_id)
      @membership = ::JointMembershipApplication.find(membership_id)

      CustomerCreator.call(@membership)
    rescue CustomerCreator::CreateCustomerException => e
      logger.error "Failed to create TicketSource customer for #{membership_id} - #{e.message}"
    end
  end
end
