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

        config_result = resolve_provider_config(provider)
        return config_error_result(config_result[:error], evaluation, provider) unless config_result[:success]

        config = config_result[:config]
        baseline_output = spawn_agent(evaluation, nil, provider, config)
        return agent_error_result(baseline_output, 'baseline', evaluation, provider) if baseline_output[:status] == :error

        context_output = spawn_agent(evaluation, skills, provider, config)
        return agent_error_result(context_output, 'context', evaluation, provider) if context_output[:status] == :error

        criteria = evaluation.criteria
        skill_context = load_combined_skill_context(skills)
        judge_params = build_judge_params(provider, config)

        result = EvaluationRunner.call(
          task: evaluation.task,
          criteria: criteria,
          skill_context: skill_context,
          baseline_output: format_output(baseline_output),
          context_output: format_output(context_output),
          judge_params: judge_params
        )

        return enrich_error_result(result, evaluation, provider) unless result[:success]

        trend = record_and_compute_trend(result)
        return enrich_error_result(result, evaluation, provider) unless trend

        {
          success: true,
          eval_name: eval_name,
          skill_name: skill_names.join(', '),
          provider_name: provider.name,
          response: result[:response].merge(trend: trend)
        }
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

      def resolve_provider_config(provider)
        { success: true, config: provider.merged_config }
      rescue ArgumentError => e
        { success: false, error: e }
      end

      def resolve_provider
        config = SkillBench::Models::Config.load
        provider = config.to_provider
        return provider if provider

        warn 'Config load failed, using mock provider'
        MOCK_PROVIDER.new('mock', 'mock', 'mock', {})
      end

      def spawn_agent(evaluation, skills, provider, config)
        return { result: 'mock result', status: :success } if provider.name == 'mock'

        client_class = SkillBench::Clients::ProviderRegistry.for(provider.runtime.to_sym)
        config ||= begin
          provider.merged_config
        rescue StandardError
          nil
        end
        options = config.dup
        options[:model] ||= provider.llm

        system_prompt = skills ? load_combined_skill_context(skills) : ''

        response = client_class.call(
          system_prompt: system_prompt,
          messages: [{ role: 'user', content: evaluation.task }],
          **options
        )

        status = response[:success] ? :success : :error
        {
          result: response[:result],
          status: status,
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

      def build_judge_params(provider, config)
        return {} if provider.name == 'mock'

        config ||= begin
          provider.merged_config
        rescue StandardError
          nil
        end
        return {} unless config

        {
          api_key: config[:api_key],
          model: config[:model] || provider.llm,
          provider: provider.runtime.to_sym
        }
      rescue StandardError
        {}
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

      def config_error_result(error, evaluation, provider)
        {
          success: false,
          response: {
            error: {
              message: "Configuration error: #{error.message}"
            }
          },
          eval_name: evaluation.name,
          skill_name: skill_names.join(', '),
          provider_name: provider.name
        }
      end

      def enrich_error_result(result, evaluation, provider)
        result.merge(
          eval_name: evaluation.name,
          skill_name: skill_names.join(', '),
          provider_name: provider.name
        )
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
