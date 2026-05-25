# Eval: tdd-process-basic

## Task
Create a simple `UserValidator` class that validates an email and a password:
1. Validates that the email contains a '@' symbol and a domain extension.
2. Validates that the password is at least 8 characters long.
3. Exposes a `.valid?` class method returning true or false.

You MUST use a strict TDD (Red-Green-Refactor) process:
- Write a failing test first (proving it fails for the right reason).
- Present the failing test and failure output before writing any implementation.
- Write minimal code to pass the test.
- Refactor the code in small, verified steps.

## Success Criteria
- The implementation has a `UserValidator` class.
- The tests are written first and successfully run.
- Both happy path and validation failures are fully tested.
