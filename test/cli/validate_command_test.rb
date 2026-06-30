# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  module Cli
    class ValidateCommandTest < Minitest::Test
      ENV_KEYS = %w[
        SKILL_BENCH_OPENAI_API_KEY OPENAI_API_KEY
        SKILL_BENCH_OPENAI_MODEL OPENAI_MODEL
      ].freeze

      def setup
        @original_dir = Dir.pwd
        @tmp_dir = Dir.mktmpdir('validate_command_test')
        Dir.chdir(@tmp_dir)
        @saved_env = ENV_KEYS.to_h { |key| [key, ENV.fetch(key, nil)] }
        ENV_KEYS.each { |key| ENV.delete(key) }
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
        @saved_env.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
        Models::Config.instance_variable_set(:@loaded, nil)
      end

      def test_all_checks_pass_with_mock_provider
        write_config(provider: 'mock', max_execution_time: 30)
        File.write('criteria.json', valid_criteria_json)

        exit_code = nil
        output = capture_stdout { exit_code = ValidateCommand.call([]) }

        assert_equal 0, exit_code
        assert_includes output, 'All checks passed.'
        assert_includes output, '[PASS] criteria'
        assert_includes output, '[PASS] config'
      end

      def test_invalid_criteria_fails
        write_config(provider: 'mock', max_execution_time: 30)
        File.write('criteria.json', invalid_criteria_json)

        exit_code = nil
        output = capture_stdout { exit_code = ValidateCommand.call([]) }

        assert_equal 1, exit_code
        assert_includes output, '[FAIL] criteria'
        assert_includes output, '1 check(s) failed.'
      end

      def test_missing_criteria_is_skipped_not_failed
        write_config(provider: 'mock', max_execution_time: 30)

        exit_code = nil
        output = capture_stdout { exit_code = ValidateCommand.call([]) }

        assert_equal 0, exit_code
        assert_includes output, '[SKIP] criteria'
        assert_includes output, 'All checks passed.'
      end

      def test_explicit_missing_criteria_path_fails
        write_config(provider: 'mock', max_execution_time: 30)

        exit_code = nil
        output = capture_stdout { exit_code = ValidateCommand.call(['--criteria', 'nope.json']) }

        assert_equal 1, exit_code
        assert_includes output, '[FAIL] criteria'
        assert_includes output, 'nope.json'
      end

      def test_invalid_provider_in_config_fails
        write_config(provider: 'not-a-provider', max_execution_time: 30, config: {})

        exit_code = nil
        output = capture_stdout { exit_code = ValidateCommand.call([]) }

        assert_equal 1, exit_code
        assert_includes output, '[FAIL] config'
        assert_includes output, 'is not one of'
      end

      def test_non_json_config_fails
        File.write('skill-bench.json', '{ not valid json')

        exit_code = nil
        output = capture_stdout { exit_code = ValidateCommand.call([]) }

        assert_equal 1, exit_code
        assert_includes output, '[FAIL] config'
        assert_includes output, 'not valid JSON'
      end

      def test_non_positive_max_execution_time_fails
        write_config(provider: 'mock', max_execution_time: 0)

        exit_code = nil
        output = capture_stdout { exit_code = ValidateCommand.call([]) }

        assert_equal 1, exit_code
        assert_includes output, '[FAIL] config'
        assert_includes output, "'max_execution_time' must be a positive integer"
      end

      def test_missing_provider_key_for_non_mock_fails
        write_config(provider: 'openai', max_execution_time: 30, config: { api_key: nil, model: 'gpt-4o' })

        exit_code = nil
        output = capture_stdout { exit_code = ValidateCommand.call([]) }

        assert_equal 1, exit_code
        assert_includes output, '[FAIL] provider key'
        assert_includes output, 'openai is missing'
      end

      def test_provider_key_present_in_config_passes
        write_config(provider: 'openai', max_execution_time: 30, config: { api_key: 'sk-test-123', model: 'gpt-4o' })

        exit_code = nil
        output = capture_stdout { exit_code = ValidateCommand.call([]) }

        assert_equal 0, exit_code
        assert_includes output, '[PASS] provider key'
        assert_includes output, 'openai credentials present'
      end

      def test_mock_provider_passes_key_check
        write_config(provider: 'mock', max_execution_time: 30)

        output = capture_stdout { ValidateCommand.call([]) }

        assert_includes output, '[PASS] provider key'
        assert_includes output, 'mock provider requires no API key'
      end

      def test_missing_config_file_fails
        File.write('criteria.json', valid_criteria_json)

        exit_code = nil
        output = capture_stdout { exit_code = ValidateCommand.call([]) }

        assert_equal 1, exit_code
        assert_includes output, '[FAIL] config'
        assert_includes output, 'skill-bench.json not found'
      end

      def test_help_flag_returns_zero
        exit_code = nil
        capture_stdout { exit_code = ValidateCommand.call(['--help']) }

        assert_equal 0, exit_code
      end

      private

      def capture_stdout
        original = $stdout
        $stdout = StringIO.new
        yield
        $stdout.string
      ensure
        $stdout = original
      end

      def write_config(config)
        File.write('skill-bench.json', JSON.generate(config))
      end

      def valid_criteria_json
        {
          context: 'Evaluate test',
          dimensions: [
            { name: 'correctness', max_score: 30 },
            { name: 'skill_adherence', max_score: 25 },
            { name: 'code_quality', max_score: 20 },
            { name: 'test_coverage', max_score: 15 },
            { name: 'documentation', max_score: 10 }
          ],
          pass_threshold: 70,
          minimum_delta: 10
        }.to_json
      end

      def invalid_criteria_json
        {
          context: 'Broken',
          dimensions: [{ name: 'correctness', max_score: 50 }],
          pass_threshold: 70,
          minimum_delta: 10
        }.to_json
      end
    end
  end
end
