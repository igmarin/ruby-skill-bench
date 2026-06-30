# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class ClientCachingTest < Minitest::Test
    # Test double provider that records how many times it is invoked, so we can
    # assert whether identical Client.call requests reach the provider or are
    # served from the cache.
    class CountingClient
      class << self
        attr_accessor :calls

        # Records an invocation and returns a canned response.
        #
        # @param system_prompt [String] System prompt (ignored)
        # @param messages [Array<Hash>] Messages (ignored)
        # @param _options [Hash] Provider options (ignored)
        # @return [Hash] A fixed success response
        def call(system_prompt:, messages:, **_options)
          _ = [system_prompt, messages]
          self.calls = (calls || 0) + 1
          { success: true, response: { message: { content: 'ok' } } }
        end
      end
    end

    def setup
      @original_env = ENV.fetch('SKILL_BENCH_CACHE', nil)
      ENV.delete('SKILL_BENCH_CACHE')
      Services::ResponseCache.clear
      CountingClient.calls = 0
      @original_providers = Clients::ProviderRegistry.providers.dup
      Clients::ProviderRegistry.register(:counting, CountingClient)
    end

    def teardown
      Clients::ProviderRegistry.instance_variable_set(:@providers, @original_providers)
      Services::ResponseCache.clear
      if @original_env.nil?
        ENV.delete('SKILL_BENCH_CACHE')
      else
        ENV['SKILL_BENCH_CACHE'] = @original_env
      end
    end

    def test_caching_disabled_invokes_provider_for_every_call
      2.times { call_counting('hi') }

      assert_equal 2, CountingClient.calls
    end

    def test_caching_enabled_dedupes_identical_calls
      ENV['SKILL_BENCH_CACHE'] = '1'

      2.times { call_counting('hi') }

      assert_equal 1, CountingClient.calls
    end

    def test_caching_enabled_distinguishes_different_inputs
      ENV['SKILL_BENCH_CACHE'] = '1'

      call_counting('a')
      call_counting('b')

      assert_equal 2, CountingClient.calls
    end

    def test_caching_enabled_returns_identical_cached_response
      ENV['SKILL_BENCH_CACHE'] = '1'

      first = call_counting('hi')
      second = call_counting('hi')

      assert_same first, second
    end

    def test_null_client_is_never_cached
      ENV['SKILL_BENCH_CACHE'] = '1'

      response = Client.call(system_prompt: 'sys', messages: [{ role: 'user', content: 'hi' }], provider: :counting_unknown)

      refute response[:success]
    end

    private

    def call_counting(content)
      Client.call(
        system_prompt: 'sys',
        messages: [{ role: 'user', content: content }],
        provider: :counting,
        model: 'gpt-4o'
      )
    end
  end
end
