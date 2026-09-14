# Create Service Object

Use when extracting or writing a Ruby service that callers invoke with `.call`.

## Pattern

```ruby
# frozen_string_literal: true

class ProcessOrder
  # Process an order from sku, quantity, and payment flag.
  #
  # @param sku [String] product identifier
  # @param quantity [Integer] units to purchase
  # @param paid [Boolean] whether payment has been captured
  # @return [Hash] `{ success: true, response: Hash }` or `{ success: false, response: { error: { message: String } } }`
  def self.call(sku:, quantity:, paid:)
    new(sku: sku, quantity: quantity, paid: paid).call
  end

  def initialize(sku:, quantity:, paid:)
    @sku = sku
    @quantity = quantity
    @paid = paid
  end

  # @return [Hash] `{ success: true, response: Hash }` or `{ success: false, response: { error: { message: String } } }`
  def call
    {
      success: true,
      response: { order_id: 1, sku: @sku, quantity: @quantity, total_cents: @quantity * 1000 }
    }
  rescue StandardError => e
    { success: false, response: { error: { message: e.message } } }
  end
end
```

## Hard rules

1. Every `.rb` file begins with `# frozen_string_literal: true`.
2. Public entry point is `def self.call(...)` delegating to `new(...).call`.
3. Success: `{ success: true, response: { ... } }`.
4. Failure: `{ success: false, response: { error: { message: '...' } } }`.
5. Document `self.call` and `#call` with YARD `@param` and `@return`.
6. Controllers and other callers stay thin: they delegate and map the result.
7. Do not put HTTP, persistence models, or UI in the service response.
