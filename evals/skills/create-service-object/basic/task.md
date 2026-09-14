# Eval: create-service-object-basic

The sandbox starts with `orders_controller.rb` and `orders_controller_test.rb`.
`OrdersController#create` validates input, prices the order, and returns a result
hash inline. Extract that processing into a `ProcessOrder` service object.

## Task

1. Add `process_order.rb` with a `ProcessOrder` PORO.
2. `ProcessOrder.call(sku:, quantity:, paid:)` must be the only public entry point
   (`def self.call(...)` → `new(...).call`).
3. Success returns `{ success: true, response: { order_id:, sku:, quantity:, total_cents: } }`.
4. Failure returns `{ success: false, response: { error: { message: '...' } } }` using
   the same messages the controller tests already expect (`sku is required`,
   `quantity must be a positive integer`, `payment required`).
5. `OrdersController#create` stays the public API and delegates to `ProcessOrder`.
   Map the service result back so `ruby orders_controller_test.rb` still passes.
6. Start `process_order.rb` with `# frozen_string_literal: true`. Document
   `self.call` and `#call` with YARD `@param` / `@return`.

## Success Criteria

- `ProcessOrder` exists with `.call`.
- The controller no longer contains pricing or validation logic.
- `ruby orders_controller_test.rb` exits 0.
- The service uses the `{ success:, response: }` contract, not the controller's
  public hash.
