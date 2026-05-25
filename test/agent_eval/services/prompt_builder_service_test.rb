# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class PromptBuilderServiceTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('prompt_builder_test')
        @evaluation = Struct.new(:task, :metadata, :path).new('Test task', {}, '/path/to/eval')
        @skills = [Struct.new(:name, :path).new('test-skill', '/path/to/skill')]
      end

      def teardown
        FileUtils.rm_rf(@tmp_dir) if @tmp_dir && Dir.exist?(@tmp_dir)
      end

      def test_build_baseline_returns_prompt
        result = PromptBuilderService.build_baseline

        assert_includes result, 'expert Ruby on Rails developer'
        assert_includes result, 'read the task'
        assert_includes result, 'modify the codebase'
      end

      def test_build_context_returns_skill_context_when_not_skill_bundle_xml
        skill_context = 'Skill instructions here'
        result = PromptBuilderService.build_context(@evaluation, @skills, skill_context)

        assert_equal skill_context, result
      end

      def test_build_context_with_skill_bundle_xml_and_source
        @evaluation = Struct.new(:task, :metadata, :path).new(
          'Test task',
          { 'context_mode' => 'skill_bundle_xml' },
          @tmp_dir
        )
        skill_context = 'Skill instructions'

        source_dir = File.join(@evaluation.path, 'source')
        FileUtils.mkpath(source_dir)
        File.write(File.join(source_dir, 'app.rb'), 'code')

        SkillBench::Execution::ContextHydrator.stubs(:call).returns(
          success: true,
          response: { context: '<agent_context>code</agent_context>' }
        )

        result = PromptBuilderService.build_context(@evaluation, @skills, skill_context)

        assert_includes result, 'Skill Instructions'
        assert_includes result, skill_context
        assert_includes result, 'Source Code'
        assert_includes result, '<agent_context>code</agent_context>'

        FileUtils.rm_rf(source_dir)
      end

      def test_build_context_falls_back_to_skill_md_when_source_missing
        @evaluation = Struct.new(:task, :metadata, :path).new(
          'Test task',
          { 'context_mode' => 'skill_bundle_xml' },
          '/path/to/eval'
        )
        skill_context = 'Skill instructions'

        SkillBench::Execution::ContextHydrator.stubs(:call).never

        result = PromptBuilderService.build_context(@evaluation, @skills, skill_context)

        assert_equal skill_context, result
      end

      def test_build_context_falls_back_when_hydrator_fails
        @evaluation = Struct.new(:task, :metadata, :path).new(
          'Test task',
          { 'context_mode' => 'skill_bundle_xml' },
          @tmp_dir
        )
        skill_context = 'Skill instructions'

        source_dir = File.join(@evaluation.path, 'source')
        FileUtils.mkpath(source_dir)

        SkillBench::Execution::ContextHydrator.stubs(:call).returns(
          success: false,
          response: { context: '' }
        )

        result = PromptBuilderService.build_context(@evaluation, @skills, skill_context)

        assert_equal skill_context, result

        FileUtils.rm_rf(source_dir)
      end
    end
  end
end
