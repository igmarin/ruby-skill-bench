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

      def test_explicit_mock_config_does_not_warn
        write_mock_config

        stderr = capture_stderr { ProviderResolver.call }

        refute_includes stderr, 'Config load failed'
      end

      def test_missing_config_still_warns
        Models::Config.instance_variable_set(:@loaded, nil)

        result = nil
        stderr = capture_stderr { result = ProviderResolver.call }

        assert_includes stderr, 'Config load failed'
        assert_equal 'mock', result[:provider].name
      end

      def test_broken_config_still_warns
        Models::Config.instance_variable_set(:@loaded, nil)
        File.write(SkillBench::Config::CONFIG_FILENAME, '{ not valid json')

        stderr = capture_stderr { ProviderResolver.call }

        assert_includes stderr, 'Config load failed'
      end

      def test_missing_provider_key_still_warns
        Models::Config.instance_variable_set(:@loaded, nil)
        File.write(SkillBench::Config::CONFIG_FILENAME, JSON.generate({ max_execution_time: 30 }))

        stderr = capture_stderr { ProviderResolver.call }

        assert_includes stderr, 'Config load failed, using mock provider'
      end

      def test_resolve_reads_config_file_once_across_calls
        write_mock_config
        loads = 0
        stub_config = Models::Config.new({ provider: 'mock', max_execution_time: 30, config: {} })

        Models::Config.stub(:load, lambda { |*_args|
          loads += 1
          stub_config
        }) do
          ProviderResolver.call
          ProviderResolver.call
        end

        assert_equal 1, loads
      end

      private

      def capture_stderr
        original = $stderr
        $stderr = StringIO.new
        yield
        $stderr.string
      ensure
        $stderr = original
      end

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
