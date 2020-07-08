# frozen_string_literal: true

require 'test_helper'

class ShirtOrderTest < ActiveSupport::TestCase
  test 'accepts valid shirt order' do
    test_this = shirt_orders(:valid_local_shirt_order)

    assert test_this.valid?
  end

  test 'rejects invalid type' do
    shirt_order = shirt_orders(:valid_local_shirt_order)
    shirt_order.shirt_type = 'invalid_shirt_type'

    assert_not shirt_order.valid?
  end

  test 'rejects incomplete order - size' do
    shirt_order = shirt_orders(:valid_local_shirt_order)
    shirt_order.shirt_size = nil

    assert_not shirt_order.valid?
  end

  test 'rejects incomplete order - color' do
    shirt_order = shirt_orders(:valid_local_shirt_order)
    shirt_order.shirt_color = nil

    assert_not shirt_order.valid?
  end
end
