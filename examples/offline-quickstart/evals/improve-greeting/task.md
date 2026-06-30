# Eval: improve-greeting

## Task
Build a `GreetingService` plain old Ruby object that turns a name into a
friendly greeting, following the PORO `.call` pattern.

## Success Criteria
- A `GreetingService` class exists with a public `self.call(name:)` class method.
- The class method delegates to a private instance `#call` method.
- `GreetingService.call(name: "Ada")` returns `"Hello, Ada!"`.
- Blank or missing input falls back to a default greeting (e.g. `"Hello, friend!"`).
- The file is frozen (`# frozen_string_literal: true`) and the public method is
  documented with YARD tags.
