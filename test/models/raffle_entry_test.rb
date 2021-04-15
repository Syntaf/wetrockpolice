# frozen_string_literal: true

require 'test_helper'

class RaffleEntryTest < ActiveSupport::TestCase
  test 'Telephone number formatted' do
    app = raffle_entries(:valid_entry)

    app.phone_number = '(111) 000-2345'
    app.save!

    assert_equal '1110002345', app.phone_number
  end

  test 'Rejects invalid email' do
    app = raffle_entries(:valid_entry)

    app.email = 'abcd'
    assert_not app.valid?
  end

  test 'Accepts empty telephone number' do
    app = raffle_entries(:valid_entry)

    app.phone_number = nil
    app.save!

    assert_nil app.phone_number
  end

  test 'Requires order_id for card payments on save' do
    app = raffle_entries(:valid_entry)

    app.order_id = nil
    assert_not app.valid?
  end

  test 'Allows nil order_id for validation' do
    app = raffle_entries(:valid_entry)
    app.order_id = nil
    app.prevalidate = true

    assert app.valid?
  end
end
