# frozen_string_literal: true

require 'test_helper'
require 'yaml'

module AgentEval
  module Models
    class ConfigTest < Minitest::Test
      def setup
        @config_path = '.agent-eval.yml'
      end

      def test_load_default_config
        YAML.stubs(:safe_load_file).with(@config_path, anything).returns({ 'providers' => { 'test' => {} } })
        config = Config.load

        assert_kind_of Config, config
        assert_kind_of Hash, config.providers
      end

      def test_load_custom_config
        custom_path = 'custom_config.yml'
        YAML.stubs(:safe_load_file).with(custom_path, anything).returns({ 'providers' => { 'test' => {} } })
        config = Config.load(custom_path)

        assert_kind_of Config, config
      end

      def test_load_nonexistent_config
        YAML.stubs(:safe_load_file).raises(Errno::ENOENT)
        config = Config.load('nonexistent.yml')

        assert_equal({}, config.providers)
      end

      def test_providers_empty
        config = Config.new({})

        assert_equal({}, config.providers)
      end
    end
  end
end
