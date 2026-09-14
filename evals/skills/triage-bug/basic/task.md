# Eval: triage-bug-basic

The sandbox starts with `discount.rb` and `discount_test.rb`.
`Discount.apply(cents: 1000, percent: 10)` returns 100 and the existing test passes.

## Bug report

Observed: 10% off 999 cents returns 90.
Expected: 99 cents (10% of 999, integer cents, truncated toward zero after the multiply).
Steps: `Discount.apply(cents: 999, percent: 10)`.

## Task

1. Restate observed vs expected. Do not patch first.
2. Add a failing test for `cents: 999, percent: 10` expecting 99. Run it and confirm it fails for the wrong result, not a syntax error.
3. Root cause: Integer `/` truncates before `*`, so `cents / 100 * percent` is not `cents * percent / 100`.
4. Smallest fix in `discount.rb` only. Keep `ruby discount_test.rb` passing, including the new case.

## Success Criteria

- A test covers 999 cents at 10% and expects 99.
- `discount.rb` uses multiply-before-divide (or equivalent that yields 99).
- `ruby discount_test.rb` exits 0.
- Do not extract a service object or add YARD as the main change.
