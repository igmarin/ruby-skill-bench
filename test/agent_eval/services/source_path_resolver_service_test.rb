# frozen_string_literal: true

require 'test_helper'
require_relative '../../../lib/skill_bench/services/source_path_resolver_service'

module SkillBench
  module Services
    class SourcePathResolverServiceTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('source_path_resolver_test')
        @eval_dir = File.join(@tmp_dir, 'evals', 'test-eval')
        FileUtils.mkpath(@eval_dir)
        @evaluation = Struct.new(:path).new(@eval_dir)
      end

      def teardown
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_returns_eval_source_when_exists
        source_dir = File.join(@eval_dir, 'source')
        FileUtils.mkpath(source_dir)

        result = SkillBench::Services::SourcePathResolverService.call(@evaluation)

        assert_equal source_dir, result
      end

      def test_call_returns_nil_when_source_missing
        result = SkillBench::Services::SourcePathResolverService.call(@evaluation)

        assert_nil result
      end

      def test_call_uses_source_path_resolver_when_eval_source_missing
        SkillBench::Config.stubs(:skill_sources).returns({})
        SkillBench::Execution::SourcePathResolver.stubs(:call).returns('/inferred/path')

        result = SkillBench::Services::SourcePathResolverService.call(@evaluation)

        assert_nil result # Since inferred path doesn't exist
      end

      def test_call_returns_inferred_path_when_exists
        inferred_path = File.join(@tmp_dir, 'inferred')
        FileUtils.mkpath(inferred_path)

        SkillBench::Config.stubs(:skill_sources).returns({})
        SkillBench::Execution::SourcePathResolver.stubs(:call).returns(inferred_path)

        result = SkillBench::Services::SourcePathResolverService.call(@evaluation)

        assert_equal inferred_path, result
      end
    end
  end
end
