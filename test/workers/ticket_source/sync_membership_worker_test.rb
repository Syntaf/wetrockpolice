# frozen_string_literal: true

require 'test_helper'

module TicketSource
  class SyncMembershipWorkerTest < ActiveSupport::TestCase
    setup do
      Sidekiq::Testing.inline!
    end

    teardown do
      Sidekiq::Testing.fake!
    end

    def test_customer_created
      membership = joint_membership_applications(:valid_application)

      service_mock = Minitest::Mock.new
      service_mock.expect(:call, true, [membership])

      CustomerCreator.stub :call, service_mock do
        SyncMembershipWorker.perform_async(membership.id)
      end

      assert_mock service_mock
    end

    def test_customer_creator_raises
      membership = joint_membership_applications(:valid_application)

      internal_error = ->(_) { raise CustomerCreator::CreateCustomerException, "oops didn't work" }
      log_mock = Minitest::Mock.new
      log_mock.expect(:error, nil, ["oops didn't work"])

      CustomerCreator.stub :call, internal_error do
        Rails.stub :logger, log_mock do
          SyncMembershipWorker.perform_async(membership.id)
        end
      end

      assert_mock log_mock
    end
  end
end
