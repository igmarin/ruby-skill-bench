# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class ErrorResponseBuilderTest < Minitest::Test
      def setup
        @evaluation = Struct.new(:name).new('test-eval')
        @provider = Struct.new(:name).new('mock')
        @skill_names = ['test-skill']
      end

      def test_config_error_builds_error_result
        error = ArgumentError.new('API key missing')
        result = ErrorResponseBuilder.config_error(error, @evaluation, @provider, @skill_names)

        refute result[:success]
        assert_includes result[:response][:error][:message], 'Configuration error'
        assert_includes result[:response][:error][:message], 'API key missing'
        assert_equal 'test-eval', result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
        assert_equal 'mock', result[:provider_name]
      end

      def test_agent_error_builds_error_result
        agent_result = { raw_response: { response: { error: { message: 'Connection failed' } } } }
        result = ErrorResponseBuilder.agent_error(agent_result, 'baseline', @evaluation, @provider, @skill_names)

        refute result[:success]
        assert_includes result[:response][:error][:message], 'Baseline agent failed'
        assert_includes result[:response][:error][:message], 'Connection failed'
        assert_equal 'test-eval', result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
        assert_equal 'mock', result[:provider_name]
      end

      def test_agent_error_handles_unknown_error
        agent_result = { raw_response: {} }
        result = ErrorResponseBuilder.agent_error(agent_result, 'context', @evaluation, @provider, @skill_names)

        refute result[:success]
        assert_includes result[:response][:error][:message], 'Context agent failed'
        assert_includes result[:response][:error][:message], 'unknown error'
      end

      def test_empty_context_error_builds_error_result
        result = ErrorResponseBuilder.empty_context_error(@evaluation, @provider, @skill_names)

        refute result[:success]
        assert_includes result[:response][:error][:message], 'Skill context is empty'
        assert_equal 'test-eval', result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
        assert_equal 'mock', result[:provider_name]
      end

      def test_enrich_error_adds_metadata
        existing_result = { success: false, response: { error: { message: 'Original error' } } }
        result = ErrorResponseBuilder.enrich_error(existing_result, @evaluation, @provider, @skill_names)

        refute result[:success]
        assert_equal 'Original error', result[:response][:error][:message]
        assert_equal 'test-eval', result[:eval_name]
        assert_equal 'test-skill', result[:skill_name]
        assert_equal 'mock', result[:provider_name]
      end

      def test_enrich_error_with_multiple_skill_names
        skill_names = %w[skill1 skill2]
        existing_result = { success: false, response: { error: { message: 'Error' } } }
        result = ErrorResponseBuilder.enrich_error(existing_result, @evaluation, @provider, skill_names)

        assert_equal 'skill1, skill2', result[:skill_name]
      end
    end
  end
end
