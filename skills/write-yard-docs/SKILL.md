# Write YARD Docs

Use when documenting Ruby public APIs with YARD.

## Pattern

```ruby
# frozen_string_literal: true

# Multiplies unit price in cents by quantity.
class PriceCalculator
  # Multiply unit cents by quantity.
  #
  # @param cents [Integer] non-negative unit price in cents
  # @param quantity [Integer] positive unit count
  # @return [Integer] total price in cents
  # @raise [ArgumentError] when cents is negative or quantity is not positive
  def self.call(cents:, quantity:)
    new(cents: cents, quantity: quantity).call
  end

  def initialize(cents:, quantity:)
    @cents = cents
    @quantity = quantity
  end

  # Multiply unit cents by quantity.
  #
  # @return [Integer] total price in cents
  # @raise [ArgumentError] when cents is negative or quantity is not positive
  def call
    raise ArgumentError, 'cents must be non-negative' if @cents.negative?
    raise ArgumentError, 'quantity must be positive' unless @quantity.positive?

    @cents * @quantity
  end
end
```

## Hard rules

1. Every public method gets YARD. Document `self.call` separately from `#call`.
2. `@param` for each argument. `@return` names the type (and Hash keys when the result is a Hash).
3. One `@raise` tag per exception class that can escape. Never group two exceptions on one tag.
4. Class gets a one-line summary.
5. YARD text is English unless the user asked otherwise.
6. Do not change runtime behavior to make the docs easier.
