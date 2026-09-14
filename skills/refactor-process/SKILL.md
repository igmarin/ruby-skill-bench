# Refactor Process

Use when restructuring Ruby without changing behavior.

## Pattern

```ruby
# frozen_string_literal: true

class OrderProcessor
  def process_standard(sku:, quantity:)
    error = validation_error(sku: sku, quantity: quantity)
    return { error: error } if error

    priced(sku: sku, quantity: quantity, shipping_cents: 500)
  end

  def process_express(sku:, quantity:)
    error = validation_error(sku: sku, quantity: quantity)
    return { error: error } if error

    priced(sku: sku, quantity: quantity, shipping_cents: 2000)
  end

  private

  def validation_error(sku:, quantity:)
    return 'sku required' if sku.to_s.strip.empty?
    return 'quantity must be positive' unless quantity.is_a?(Integer) && quantity.positive?

    nil
  end

  def priced(sku:, quantity:, shipping_cents:)
    { sku: sku, quantity: quantity, total_cents: quantity * 1000, shipping_cents: shipping_cents }
  end
end
```

## Hard rules

1. Characterization tests must be Green before the first edit.
2. One atomic transformation per step (extract method, then re-run tests).
3. If tests go Red, revert that step. Do not debug in a broken tree.
4. Do not change return values, error strings, or add features in the same pass.
5. Do not mix this refactor with a bug fix or a new service object.
