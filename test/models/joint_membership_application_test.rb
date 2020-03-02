# frozen_string_literal: true

require 'test_helper'

class JointMembershipApplicationTest < ActiveSupport::TestCase
  test 'Telephone number formatted' do
    app = joint_membership_applications(:valid_application)

    app.phone_number = '(111) 000-2345'
    app.save!

    assert_equal '1110002345', app.phone_number
  end

  test 'Rejects invalid email' do
    app = joint_membership_applications(:valid_application)

    app.email = 'abcd'

    assert_raises ActiveRecord::RecordInvalid do
      app.save!
    end
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

  test 'Requires order_id for card payments on save' do
    app = joint_membership_applications(:valid_application)

    assert_raises ActiveRecord::RecordInvalid do
      app.order_id = nil
      app.paid_cash = false
      app.save!
    end
  end

  test 'Allows nil order_id for validation' do
    app = joint_membership_applications(:valid_application)
    app.order_id = nil
    app.paid_cash = false
    app.prevalidate = true

    assert app.valid?
  end

  test 'Accepts nil order_id on cash payment' do
    app = joint_membership_applications(:valid_application)

    app.order_id = nil
    app.paid_cash = true
    app.save!
  end
end
