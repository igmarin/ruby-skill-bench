# Triage Bug

Use when a Ruby bug report needs a reproduction test before a fix.

## Pattern

```ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'discount'

class DiscountReproductionTest < Minitest::Test
  def test_ten_percent_off_999_cents
    assert_equal 99, Discount.apply(cents: 999, percent: 10)
  end
end
```

## Hard rules

1. Do not patch production code until a test fails for the reported case.
2. The first failing test must fail on the assertion (wrong value), not LoadError or syntax.
3. Name observed behavior, expected behavior, and the smallest file to change.
4. Fix only that behavior. Do not refactor, extract a service, or add unrelated docs.
5. Re-run the full fixture tests after the fix.
