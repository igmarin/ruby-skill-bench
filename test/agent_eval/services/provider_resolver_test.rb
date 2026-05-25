# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class ProviderResolverTest < Minitest::Test
      def setup
        @original_dir = Dir.pwd
        @tmp_dir = Dir.mktmpdir('provider_resolver_test')
        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
        Models::Config.instance_variable_set(:@loaded, nil)
      end

      def test_call_resolves_provider_and_config
        write_mock_config

        result = ProviderResolver.call

        assert result[:success]
        assert_equal 'mock', result[:provider].name
        assert_equal({}, result[:config])
      end

      def test_call_returns_error_when_config_fails
        Models::Config.instance_variable_set(:@loaded, nil)
        File.write(SkillBench::Config::CONFIG_FILENAME, JSON.generate({
                                                                        provider: 'openai',
                                                                        max_execution_time: 30,
                                                                        config: { api_key: nil }
                                                                      }))

        result = ProviderResolver.call

        refute result[:success]
        assert_kind_of ArgumentError, result[:error]
        assert result[:provider]
      end

      private

      def write_mock_config
        Models::Config.instance_variable_set(:@loaded, nil)
        File.write(SkillBench::Config::CONFIG_FILENAME, JSON.generate({
                                                                        provider: 'mock',
                                                                        max_execution_time: 30,
                                                                        config: {}
                                                                      }))
      end
    end
  end
end
