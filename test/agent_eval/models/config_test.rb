# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  module Models
    class ConfigTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('config_test')
        @original_dir = Dir.pwd
        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_load_default_config
        config_data = {
          provider: 'openai',
          max_execution_time: 30,
          config: { api_key: nil, model: 'gpt-4o' }
        }
        File.write('skill-bench.json', JSON.generate(config_data))

        config = Config.load

        assert_kind_of Config, config
        assert_equal 'openai', config.provider_name
        assert_equal 30, config.max_execution_time
      end

      def test_load_custom_config
        config_data = {
          provider: 'gemini',
          max_execution_time: 60,
          config: { api_key: nil, model: 'gemini-flash' }
        }
        File.write('custom-config.json', JSON.generate(config_data))

        config = Config.load('custom-config.json')

        assert_kind_of Config, config
        assert_equal 'gemini', config.provider_name
        assert_equal 60, config.max_execution_time
      end

      def test_load_nonexistent_config
        assert_raises(Errno::ENOENT) do
          Config.load('nonexistent.json')
        end
      end

      def test_provider_config
        config_data = {
          provider: 'openai',
          max_execution_time: 30,
          config: { api_key: 'test-key', model: 'gpt-4o' }
        }
        File.write('skill-bench.json', JSON.generate(config_data))

        config = Config.load

        assert_equal({ api_key: 'test-key', model: 'gpt-4o' }, config.provider_config)
      end

      def test_max_execution_time_default
        config = Config.new({})

        assert_equal 30, config.max_execution_time
      end

      def test_mock_predicate_true_for_mock_provider
        assert_predicate Config.new({ provider: 'mock' }), :mock?
      end

      def test_mock_predicate_false_for_other_or_missing_provider
        refute_predicate Config.new({ provider: 'openai' }), :mock?
        refute_predicate Config.new({}), :mock?
      end

      def test_loaded_memoizes_and_reads_file_once
        Config.instance_variable_set(:@loaded, nil)
        File.write('skill-bench.json', JSON.generate({ provider: 'mock', max_execution_time: 30, config: {} }))
        loads = 0
        stub_config = Config.new({ provider: 'mock', max_execution_time: 30, config: {} })

        Config.stub(:load, lambda { |*_args|
          loads += 1
          stub_config
        }) do
          first = Config.loaded
          second = Config.loaded

          assert_same first, second
        end

        assert_equal 1, loads
      ensure
        Config.instance_variable_set(:@loaded, nil)
      end
    end
  end
end
