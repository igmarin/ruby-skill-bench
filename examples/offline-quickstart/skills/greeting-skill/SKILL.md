# Skill: greeting-skill

## Description
Build greeting logic as a plain old Ruby object (PORO) service following the
`.call` pattern. The service takes a name and returns a friendly greeting,
exposing a single public class method and keeping all behaviour testable.

## Context
A greeting service object encapsulates one responsibility: turning an input
name into a greeting string. It uses the `.call` convention so callers never
instantiate the object directly, freezes string literals for safety, and is
documented with YARD tags.

```ruby
# frozen_string_literal: true

# Builds a friendly greeting for a given name.
class GreetingService
  # Build a greeting for the supplied name.
  #
  # @param name [String] the person to greet.
  # @return [String] the formatted greeting.
  def self.call(name:)
    new(name: name).call
  end

  # @param name [String] the person to greet.
  def initialize(name:)
    @name = name
  end

  # @return [String] the formatted greeting.
  def call
    "Hello, #{normalized_name}!"
  end

  private

  attr_reader :name

  def normalized_name
    name.to_s.strip.empty? ? 'friend' : name.strip
  end
end
```

## Workflow
1. Define a single class with a public `self.call` class method.
2. Delegate `self.call` to an instance `#call` method (PORO `.call` pattern).
3. Keep collaborators private; expose only what callers need.
4. Return a `String` greeting; handle blank input by defaulting to `friend`.

## Hard rules
- MUST start the file with `# frozen_string_literal: true`.
- MUST expose exactly one public class method: `self.call`.
- MUST delegate the class method to a private instance method.
- MUST document the public method and parameters with YARD (`@param`, `@return`).
- MUST keep helper methods private.
- MUST NOT perform any I/O (no `puts`, no network, no file access).
