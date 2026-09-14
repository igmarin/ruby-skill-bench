# frozen_string_literal: true

class PriceCalculator
  def self.call(cents:, quantity:)
    new(cents: cents, quantity: quantity).call
  end

  def initialize(cents:, quantity:)
    @cents = cents
    @quantity = quantity
  end

  def call
    raise ArgumentError, 'cents must be non-negative' if @cents.negative?
    raise ArgumentError, 'quantity must be positive' unless @quantity.positive?

    @cents * @quantity
  end
end
