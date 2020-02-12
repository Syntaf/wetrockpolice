# frozen_string_literal: true

require 'test_helper'

class JointMembershipApplicationTest < ActiveSupport::TestCase
  test 'Missing required info' do
    assert_raises ActiveRecord::RecordInvalid do
      JointMembershipApplication.create!({})
    end
  end

  test 'Telephone number formatted' do
    app = joint_membership_applications(:valid_application)

    app.phone_number = '(111) 000-2345'
    app.save!

    assert_equal '1110002345', app.phone_number
  end

  test 'Accepts empty telephone number' do
    app = joint_membership_applications(:valid_application)

    app.phone_number = nil
    app.save!

    assert_nil app.phone_number
  end

  test 'Rejects non-numeric zipcode' do
    app = joint_membership_applications(:valid_application)

    assert_raises ActiveRecord::RecordInvalid do
      app.zipcode = 'should error'
      app.save!
    end
  end

  test 'Rejects too long zipcode' do
    app = joint_membership_applications(:valid_application)

    assert_raises ActiveRecord::RecordInvalid do
      app.zipcode = '123456789'
      app.save!
    end
  end
end
