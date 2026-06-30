# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class ResponseCacheTest < Minitest::Test
      def setup
        @original_env = ENV.fetch('SKILL_BENCH_CACHE', nil)
        ENV.delete('SKILL_BENCH_CACHE')
        ResponseCache.clear
      end

      def teardown
        ResponseCache.clear
        if @original_env.nil?
          ENV.delete('SKILL_BENCH_CACHE')
        else
          ENV['SKILL_BENCH_CACHE'] = @original_env
        end
      end

      def test_disabled_by_default
        refute_predicate ResponseCache, :enabled?
      end

      def test_enabled_when_env_truthy
        ENV['SKILL_BENCH_CACHE'] = '1'

        assert_predicate ResponseCache, :enabled?
      end

      def test_enabled_for_other_truthy_values
        %w[true yes on TRUE Yes].each do |raw|
          ENV['SKILL_BENCH_CACHE'] = raw

          assert_predicate ResponseCache, :enabled?, "expected #{raw.inspect} to enable caching"
        end
      end

      def test_disabled_when_env_falsey
        ENV['SKILL_BENCH_CACHE'] = '0'

        refute_predicate ResponseCache, :enabled?
      end

      def test_same_inputs_produce_same_key
        first = build_key
        second = build_key

        assert_equal first, second
      end

      def test_key_is_independent_of_message_hash_key_order
        ordered = ResponseCache.key(**base_args, messages: [{ role: 'user', content: 'hi' }])
        shuffled = ResponseCache.key(**base_args, messages: [{ content: 'hi', role: 'user' }])

        assert_equal ordered, shuffled
      end

      def test_symbol_and_string_provider_match
        as_symbol = ResponseCache.key(**base_args, provider: :openai)
        as_string = ResponseCache.key(**base_args, provider: 'openai')

        assert_equal as_symbol, as_string
      end

      def test_different_model_produces_different_key
        gpt4o = ResponseCache.key(**base_args, model: 'gpt-4o')
        mini = ResponseCache.key(**base_args, model: 'gpt-4o-mini')

        refute_equal gpt4o, mini
      end

      def test_different_messages_produce_different_key
        first = ResponseCache.key(**base_args, messages: [{ role: 'user', content: 'a' }])
        second = ResponseCache.key(**base_args, messages: [{ role: 'user', content: 'b' }])

        refute_equal first, second
      end

      def test_different_tools_produce_different_key
        without = ResponseCache.key(**base_args, tools: nil)
        with = ResponseCache.key(**base_args, tools: [{ name: 'search' }])

        refute_equal without, with
      end

      def test_key_is_a_hex_sha256_digest
        assert_match(/\A[0-9a-f]{64}\z/, build_key)
      end

      def test_fetch_yields_and_stores_on_miss
        calls = 0
        value = ResponseCache.fetch('k') do
          calls += 1
          'computed'
        end

        assert_equal 'computed', value
        assert_equal 1, calls
      end

      def test_fetch_returns_cached_value_without_yielding_on_hit
        cached = 'first'
        ResponseCache.fetch('k') { cached }

        calls = 0
        value = ResponseCache.fetch('k') do
          calls += 1
          'second'
        end

        assert_equal 'first', value
        assert_equal 0, calls
      end

      def test_clear_empties_the_store
        original = 'first'
        ResponseCache.fetch('k') { original }
        ResponseCache.clear

        replacement = 'second'
        recomputed = ResponseCache.fetch('k') { replacement }

        assert_equal 'second', recomputed
      end

      private

      def base_args
        {
          provider: :openai,
          model: 'gpt-4o',
          system_prompt: 'You are helpful',
          messages: [{ role: 'user', content: 'hi' }],
          tools: nil,
          temperature: 0.0
        }
      end

      def build_key
        ResponseCache.key(**base_args)
      end
    end
  end
end
