# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  module Commands
    class InitTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('skill_bench_init_test')
        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir('/')
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_run_creates_config_file
        Init.run(force: false)

        assert_path_exists SkillBench::Config::CONFIG_FILENAME
      end

      def test_run_creates_valid_json
        Init.run(force: false)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content, symbolize_names: true)

        assert config.key?(:current_llm_provider)
        assert config.key?(:providers)
        assert config[:providers].key?(:openai)
        assert_equal 'gpt-4o', config[:providers][:openai][:model]
      end

      def test_run_raises_when_file_exists_and_not_force
        File.write(SkillBench::Config::CONFIG_FILENAME, 'existing')

        assert_raises(RuntimeError) { Init.run(force: false) }
      end

      def test_run_overwrites_when_force_true
        File.write(SkillBench::Config::CONFIG_FILENAME, '{"invalid": true}')

        Init.run(force: true)

        content = File.read(SkillBench::Config::CONFIG_FILENAME)
        config = JSON.parse(content)
        refute_equal({ 'invalid' => true }, config)
        assert config.key?('current_llm_provider')
      end
    end
  end
end
