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

# Tests must be hermetic: never inherit provider settings from the developer's
# shell. Leaked keys/models (e.g. OPENAI_API_KEY, DEEPSEEK_MODEL) flow through
# Provider#merged_config and make assertions pass/fail based on the machine,
# not the code. Tests that exercise env handling set their own vars in setup
# and restore them in teardown.
#
# Strip both SKILL_BENCH_<PROVIDER>_<SETTING> and legacy <PROVIDER>_<SETTING>
# for every EnvOverrides-capable setting on every registered provider.
%w[OPENAI ANTHROPIC GEMINI OLLAMA AZURE GROQ DEEPSEEK MISTRAL OPENCODE OPENROUTER]
  .product(%w[API_KEY MODEL BASE_URL ENDPOINT LOCATION PROJECT_ID API_VERSION])
  .each do |provider, setting|
    ENV.delete("#{provider}_#{setting}")
    ENV.delete("SKILL_BENCH_#{provider}_#{setting}")
  end
