# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require 'minitest/autorun'
require 'mocha/minitest'
require 'webmock/minitest'

# Load the library via the canonical entry point
$LOAD_PATH << File.expand_path('../lib', __dir__)
require_relative '../lib/skill_bench'

# Tests must be hermetic: never inherit real provider credentials from the
# developer's shell. A leaked key (e.g. OPENAI_API_KEY) flows through
# EnvOverrides / Provider#merged_config / ProviderConfig and makes
# "missing credentials" assertions pass, so the suite would go red only on
# machines that have keys exported. Tests that exercise env handling set their
# own vars in setup and restore them in teardown.
ENV.keys.grep(/_API_KEY\z/).each { |provider_key| ENV.delete(provider_key) }
