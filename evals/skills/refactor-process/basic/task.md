# Eval: refactor-process-basic

The sandbox starts with `order_processor.rb` and `order_processor_test.rb`.
`process_standard` and `process_express` duplicate sku/quantity guards and unit pricing.
The tests already capture current behavior and pass.

## Task

1. Run `ruby order_processor_test.rb` and confirm Green before any edit.
2. Extract the duplicated validation (and optionally pricing) into a private helper. One atomic transformation at a time.
3. Re-run the tests after each step. If Red, revert that step.
4. Do not change return hashes, error strings, or shipping amounts.
5. Do not fix bugs, add YARD, or extract a `ProcessOrder` service as the main change.

## Success Criteria

- Duplicated sku/quantity checks live in one place.
- `ruby order_processor_test.rb` exits 0.
- Public methods `process_standard` and `process_express` still exist with the same results.
