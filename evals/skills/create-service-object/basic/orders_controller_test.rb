# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'orders_controller'

class OrdersControllerTest < Minitest::Test
  def setup
    @controller = OrdersController.new
  end

  def test_create_charges_and_returns_order
    result = @controller.create(sku: 'SKU-1', quantity: 2, paid: true)

    assert_equal 1, result[:order_id]
    assert_equal 'SKU-1', result[:sku]
    assert_equal 2, result[:quantity]
    assert_equal 2000, result[:total_cents]
  end

  def test_create_rejects_blank_sku
    result = @controller.create(sku: '  ', quantity: 1, paid: true)

    assert_equal 'sku is required', result[:error]
  end

  def test_create_rejects_non_positive_quantity
    result = @controller.create(sku: 'SKU-1', quantity: 0, paid: true)

    assert_equal 'quantity must be a positive integer', result[:error]
  end

  def test_create_rejects_unpaid
    result = @controller.create(sku: 'SKU-1', quantity: 1, paid: false)

    assert_equal 'payment required', result[:error]
  end
end
