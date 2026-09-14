# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'discount'

class DiscountTest < Minitest::Test
  def test_ten_percent_off_1000_cents
    assert_equal 100, Discount.apply(cents: 1000, percent: 10)
  end
end
