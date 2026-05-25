# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Services
    class AgentSpawnerServiceTest < Minitest::Test
      def setup
        @evaluation = Struct.new(:task, :path).new('Test task', '/path/to/eval')
        @system_prompt = 'You are an expert'
        @provider = Struct.new(:name, :runtime, :llm, :merged_config).new('mock', 'mock', 'mock', {})
        @config = {}
      end

      def test_call_returns_mock_result_for_mock_provider
        result = AgentSpawnerService.call(@evaluation, @system_prompt, @provider, @config)

        assert_equal :success, result[:status]
        assert_equal 'mock result', result[:result]
        assert_equal [], result[:iterations]
      end
    end
  end
end
