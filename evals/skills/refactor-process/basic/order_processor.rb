# frozen_string_literal: true

class OrderProcessor
  UNIT_CENTS = 1000
  STANDARD_SHIPPING_CENTS = 500
  EXPRESS_SHIPPING_CENTS = 2000

  def process_standard(sku:, quantity:)
    return { error: 'sku required' } if sku.to_s.strip.empty?
    return { error: 'quantity must be positive' } unless quantity.is_a?(Integer) && quantity.positive?

    { sku: sku, quantity: quantity, total_cents: quantity * UNIT_CENTS, shipping_cents: STANDARD_SHIPPING_CENTS }
  end

  def process_express(sku:, quantity:)
    return { error: 'sku required' } if sku.to_s.strip.empty?
    return { error: 'quantity must be positive' } unless quantity.is_a?(Integer) && quantity.positive?

    { sku: sku, quantity: quantity, total_cents: quantity * UNIT_CENTS, shipping_cents: EXPRESS_SHIPPING_CENTS }
  end
end
