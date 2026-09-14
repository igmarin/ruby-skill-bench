# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'price_calculator'

class PriceCalculatorTest < Minitest::Test
  def test_call_multiplies_cents_by_quantity
    assert_equal 2000, PriceCalculator.call(cents: 1000, quantity: 2)
  end

  def test_call_rejects_negative_cents
    error = assert_raises(ArgumentError) { PriceCalculator.call(cents: -1, quantity: 1) }

    assert_equal 'cents must be non-negative', error.message
  end

  def test_call_rejects_non_positive_quantity
    error = assert_raises(ArgumentError) { PriceCalculator.call(cents: 1000, quantity: 0) }

    assert_equal 'quantity must be positive', error.message
  end
end
