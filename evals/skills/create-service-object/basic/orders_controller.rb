# frozen_string_literal: true

# Handles order creation. Pricing, validation, and persistence-shaped
# output all live in this action — extract them into a service object.
class OrdersController
  PRICE_CENTS = 1000

  def create(sku:, quantity:, paid:)
    return { error: 'sku is required' } if sku.to_s.strip.empty?
    return { error: 'quantity must be a positive integer' } unless quantity.is_a?(Integer) && quantity.positive?
    return { error: 'payment required' } unless paid

    {
      order_id: 1,
      sku: sku,
      quantity: quantity,
      total_cents: quantity * PRICE_CENTS
    }
  end
end
