# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'order_processor'

class OrderProcessorTest < Minitest::Test
  def setup
    @processor = OrderProcessor.new
  end

  def test_standard_prices_units_and_shipping
    result = @processor.process_standard(sku: 'SKU-1', quantity: 2)

    assert_equal 'SKU-1', result[:sku]
    assert_equal 2, result[:quantity]
    assert_equal 2000, result[:total_cents]
    assert_equal 500, result[:shipping_cents]
  end

  def test_express_uses_higher_shipping
    result = @processor.process_express(sku: 'SKU-1', quantity: 2)

    assert_equal 2000, result[:total_cents]
    assert_equal 2000, result[:shipping_cents]
  end

  def test_standard_rejects_blank_sku
    result = @processor.process_standard(sku: '  ', quantity: 1)

    assert_equal 'sku required', result[:error]
  end

  def test_express_rejects_non_positive_quantity
    result = @processor.process_express(sku: 'SKU-1', quantity: 0)

    assert_equal 'quantity must be positive', result[:error]
  end
end
