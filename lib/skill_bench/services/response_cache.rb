# frozen_string_literal: true

require 'digest'
require 'json'

module SkillBench
  module Services
    # Content-addressed, in-memory cache for LLM responses.
    #
    # The cache is opt-in and disabled by default. When enabled it lets repeated,
    # identical LLM requests reuse a previously computed response instead of
    # hitting the network again. The canonical example is `compare`, which runs
    # the skill-less baseline twice with identical inputs.
    #
    # The backing store is a process-lifetime {Hash} keyed by a stable SHA-256
    # digest of the request, so the same logical request always maps to the same
    # entry regardless of hash-key ordering.
    class ResponseCache
      # Environment variable that opts caching on when set to a truthy value.
      ENV_FLAG = 'SKILL_BENCH_CACHE'

      # Raw env values treated as "on".
      TRUTHY_VALUES = %w[1 true yes on].freeze

      class << self
        # Whether response caching is currently enabled.
        #
        # Enabled when {ENV_FLAG} is set to a truthy value (one of
        # {TRUTHY_VALUES}); disabled when unset or set to anything else.
        #
        # @return [Boolean] true when caching is on
        def enabled?
          raw = ENV.fetch(ENV_FLAG, '').to_s.strip.downcase
          TRUTHY_VALUES.include?(raw)
        end

        # Computes a stable content-addressed cache key for a request.
        #
        # The inputs are assembled into a canonical structure (hash keys sorted
        # and stringified recursively) and hashed, so semantically identical
        # requests always produce the same digest.
        #
        # @param provider [Symbol, String] Resolved provider identifier
        # @param model [String, nil] Model name
        # @param system_prompt [String] System prompt
        # @param messages [Array<Hash>] Conversation messages
        # @param tools [Array<Hash>, nil] Tool definitions, when present
        # @param temperature [Float, nil] Sampling temperature, when present
        # @return [String] Hex-encoded SHA-256 digest of the canonical request
        def key(provider:, model:, system_prompt:, messages:, tools: nil, temperature: nil)
          payload = {
            provider: provider.to_s,
            model: model,
            system_prompt: system_prompt,
            messages: messages,
            tools: tools,
            temperature: temperature
          }
          Digest::SHA256.hexdigest(JSON.generate(canonicalize(payload)))
        end

        # Returns the cached value for a key, computing and storing it on a miss.
        #
        # @param key [String] Cache key from {key}
        # @yield Computes the value to cache when the key is absent
        # @yieldreturn [Object] The value to cache
        # @return [Object] The cached value (existing on a hit, freshly stored on a miss)
        def fetch(key)
          cache = store
          return cache[key] if cache.key?(key)

          cache[key] = yield
        end

        # Removes every cached entry.
        #
        # @return [void]
        def clear
          store.clear
        end

        private

        # The process-lifetime backing store.
        #
        # @return [Hash{String => Object}] digest => cached response
        def store
          @store ||= {}
        end

        # Recursively rewrites a value into a stable form for serialization.
        #
        # Hashes get their keys stringified and sorted so that key ordering does
        # not affect the resulting digest; arrays and scalars are preserved.
        #
        # @param value [Object] The value to canonicalize
        # @return [Object] A canonical, order-stable copy of the value
        def canonicalize(value)
          case value
          when Hash
            value
              .sort_by { |entry| entry.first.to_s }
              .each_with_object({}) { |(name, val), acc| acc[name.to_s] = canonicalize(val) }
          when Array
            value.map { |element| canonicalize(element) }
          else
            value
          end
        end
      end
    end
  end
end
