# Eval: write-yard-docs-basic

The sandbox starts with `price_calculator.rb` and `price_calculator_test.rb`.
`PriceCalculator` already works. Public methods have no YARD.

## Task

Add YARD to `PriceCalculator` without changing behavior.

1. Class: one-line summary of responsibility.
2. `self.call` and `#call` each get their own docs. Do not document only one of them.
3. Every public method gets `@param`, `@return`, and `@raise` where they apply.
4. `@param` for `cents` and `quantity` on `self.call` (and on `initialize` if you treat it as public).
5. `@return` states the type (`Integer` total cents, or the Hash/result shape if you change nothing else).
6. One `@raise [ArgumentError]` tag per raising method, with the actual messages (`cents must be non-negative`, `quantity must be positive`). Do not group exceptions on one tag.
7. Leave `ruby price_calculator_test.rb` passing. Do not add `process_order.rb` or extract a new service.

## Success Criteria

- All public methods have YARD.
- `@param` tags match `cents:` and `quantity:`.
- `@return` names the return type.
- `@raise` documents `ArgumentError` on methods that raise.
- `ruby price_calculator_test.rb` exits 0.
