# frozen_string_literal: true

require 'json'
require_relative '../models/eval'
require_relative '../models/skill'
require_relative '../models/config'
require_relative '../models/provider'
require_relative '../clients/all'
require_relative 'skill_resolver'
require_relative '../benchmark_recorder'

module SkillBench
  module Services
    # Orchestrates the execution of an eval with baseline and context runs.
    class RunnerService
      # Stand-in provider when no LLM config is available.
      MOCK_PROVIDER = Struct.new(:name, :runtime, :llm, :merged_config)
      private_constant :MOCK_PROVIDER

      # Runs an eval with the given parameters.
      #
      # @param eval_name [String] Name or path of the eval to run
      # @param skill_names [Array<String>] Names of the skills to use
      # @return [Hash] Result from EvaluationRunner
      def self.call(eval_name:, skill_names:)
        new(eval_name: eval_name, skill_names: skill_names).call
      end

      # @param eval_name [String] Name or path of the eval
      # @param skill_names [Array<String>] Names of the skills
      def initialize(eval_name:, skill_names:)
        @eval_name = eval_name
        @skill_names = skill_names
      end

      # Executes the eval: resolves entities, runs baseline and context, evaluates.
      #
      # @return [Hash] Evaluation result with deltas and verdict.
      # @raise [Errno::ENOENT] when the eval directory does not exist.
      # @raise [ArgumentError] when a skill cannot be resolved.
      def call
        evaluation = resolve_eval
        skills = resolve_skills
        provider = resolve_provider

        baseline_output = spawn_agent(evaluation, nil, provider)
        return agent_error_result(baseline_output, 'baseline', evaluation, provider) if baseline_output[:status] == :error

        context_output = spawn_agent(evaluation, skills, provider)
        return agent_error_result(context_output, 'context', evaluation, provider) if context_output[:status] == :error

        criteria = evaluation.criteria
        skill_context = load_combined_skill_context(skills)

        result = EvaluationRunner.call(
          task: evaluation.task,
          criteria: criteria,
          skill_context: skill_context,
          baseline_output: format_output(baseline_output),
          context_output: format_output(context_output)
        )

        return result unless result[:success]

        trend = record_and_compute_trend(result)
        return result unless trend

        { success: true, response: result[:response].merge(trend: trend) }
      end

      private

      attr_reader :eval_name, :skill_names

      def resolve_eval
        eval_path = eval_name.include?('/') ? eval_name : "evals/#{eval_name}"
        SkillBench::Models::Eval.load(eval_path)
      end

      def resolve_skills
        skill_names.map { |name| Services::SkillResolver.call(name) }
      end

      def resolve_provider
        config = SkillBench::Models::Config.load
        provider = config.to_provider
        return provider if provider

        warn 'Config load failed, using mock provider'
        MOCK_PROVIDER.new('mock', 'mock', 'mock', {})
      end

      def spawn_agent(evaluation, skills, provider)
        return { result: 'mock result', status: :success } if provider.name == 'mock'

        client_class = SkillBench::Clients::ProviderRegistry.for(provider.runtime.to_sym)
        config = provider.merged_config
        options = config.dup
        options[:model] ||= provider.llm

        system_prompt = skills ? load_combined_skill_context(skills) : ''

        response = client_class.call(
          system_prompt: system_prompt,
          messages: [{ role: 'user', content: evaluation.task }],
          **options
        )

        {
          result: response[:result],
          status: response[:success] ? :success : :error,
          runtime: provider.runtime,
          usage: response[:usage],
          raw_response: response[:response]
        }
      end

      def load_combined_skill_context(skills)
        return '' if skills.nil? || skills.empty?

        contexts = skills.map { |skill| load_skill_context(skill) }
        contexts.reject(&:empty?).join("\n\n#{'=' * 40}\n\n")
      end

      def load_skill_context(skill)
        skill_md = File.join(skill.path, 'SKILL.md')
        File.exist?(skill_md) ? File.read(skill_md) : ''
      end

      def format_output(agent_result)
        agent_result[:result].to_s
      end

      def agent_error_result(result, phase, evaluation, provider)
        {
          success: false,
          response: {
            error: {
              message: "#{phase.capitalize} agent failed: #{result[:raw_response]&.dig(:error, :message) || 'unknown error'}"
            }
          },
          eval_name: evaluation.name,
          skill_name: skill_names.join(', '),
          provider_name: provider.name
        }
      end

      def record_and_compute_trend(result)
        recorder = BenchmarkRecorder.new
        enriched = result.merge(eval_name: eval_name, skill_names: skill_names)
        trend = recorder.trend_for(enriched)
        recorder.record(enriched)
        trend
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'Benchmark recording failed')
        nil
      end
    end
  end
end
