# Eval: create-service-object-basic

## Task
Extract the order processing logic from the controller into a service object following the PORO `.call` pattern.

## Success Criteria
- A new service object exists with a `.call` class method.
- The controller delegates to the service object.
- The service object returns a standard { success:, response: } hash.
- All existing tests still pass.
