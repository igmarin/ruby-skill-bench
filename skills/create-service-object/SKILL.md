# Create Service Object

Use when extracting or writing a Ruby service that callers invoke with `.call`.

## Pattern

```ruby
# frozen_string_literal: true

class ProcessOrder
  def self.call(sku:, quantity:, paid:)
    new(sku: sku, quantity: quantity, paid: paid).call
  end

  def initialize(sku:, quantity:, paid:)
    @sku = sku
    @quantity = quantity
    @paid = paid
  end

  def call
    { success: true, response: { ... } }
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
