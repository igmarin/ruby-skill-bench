# frozen_string_literal: true

require_relative '../evaluation/runner'
require_relative 'eval_resolver'
require_relative 'skill_resolver_service'
require_relative 'provider_resolver'
require_relative 'prompt_builder_service'
require_relative 'agent_spawner_service'
require_relative 'context_loader_service'
require_relative 'judge_params_builder'
require_relative 'error_response_builder'
require_relative 'trend_recorder_service'
require_relative 'output_formatter'

module SkillBench
  module Services
    # Orchestrates the execution of an eval with baseline and context runs.
    # Coordinates multiple services to resolve entities, spawn agents, and evaluate results.
    class RunnerService
      # Context for evaluation and trend recording
      EvaluationContext = Struct.new(:evaluation, :skill_context, :baseline_output, :context_output, :provider, :config, keyword_init: true)
      # Runs an eval with the given parameters.
      #
      # @param eval_name [String] Name or path of the eval to run
      # @param skill_names [Array<String>] Names of the skills to use
      # @param pack [String, nil] Optional pack name for registry-based skill resolution
      # @param registry_manifest [String, nil] Optional path to registry.json manifest
      # @return [Hash] Result from EvaluationRunner
      def self.call(eval_name:, skill_names:, pack: nil, registry_manifest: nil)
        new(
          eval_name: eval_name,
          skill_names: skill_names,
          pack: pack,
          registry_manifest: registry_manifest
        ).call
      end

      # @param eval_name [String] Name or path of the eval
      # @param skill_names [Array<String>] Names of the skills
      # @param pack [String, nil] Optional pack name
      # @param registry_manifest [String, nil] Optional registry.json path
      def initialize(eval_name:, skill_names:, pack: nil, registry_manifest: nil)
        @eval_name = eval_name
        @skill_names = skill_names
        @pack = pack
        @registry_manifest = registry_manifest
      end

      # Executes the eval: resolves entities, runs baseline and context, evaluates.
      #
      # @return [Hash] Evaluation result with deltas and verdict.
      # @raise [Errno::ENOENT] when the eval directory does not exist.
      # @raise [ArgumentError] when a skill cannot be resolved.
      def call
        evaluation = EvalResolver.call(eval_name)
        skills = SkillResolverService.call(skill_names, pack: pack, registry_manifest: registry_manifest)
        provider_result = ProviderResolver.call

        return config_error_result(provider_result[:error], evaluation, provider_result[:provider]) unless provider_result[:success]

        provider = provider_result[:provider]
        config = provider_result[:config]

        baseline_output = run_baseline_agent(evaluation, provider, config)
        return agent_error_result(baseline_output, 'baseline', evaluation, provider) if baseline_output[:status] == :error

        skill_context = ContextLoaderService.call(skills)
        return empty_context_error_result(evaluation, provider) if skill_context.strip.empty?

        context_output = run_context_agent(evaluation, skills, skill_context, provider, config)
        return agent_error_result(context_output, 'context', evaluation, provider) if context_output[:status] == :error

        context = EvaluationContext.new(
          evaluation: evaluation,
          skill_context: skill_context,
          baseline_output: baseline_output,
          context_output: context_output,
          provider: provider,
          config: config
        )
        evaluate_and_record_trend(context)
      end

      private

      attr_reader :eval_name, :skill_names, :pack, :registry_manifest

      def config_error_result(error, evaluation, provider)
        ErrorResponseBuilder.config_error(error, evaluation, provider, skill_names)
      end

      def agent_error_result(result, phase, evaluation, provider)
        ErrorResponseBuilder.agent_error(result, phase, evaluation, provider, skill_names)
      end

      def empty_context_error_result(evaluation, provider)
        ErrorResponseBuilder.empty_context_error(evaluation, provider, skill_names)
      end

      def enrich_error_result(result, evaluation, provider)
        ErrorResponseBuilder.enrich_error(result, evaluation, provider, skill_names)
      end

      def run_baseline_agent(evaluation, provider, config)
        baseline_prompt = PromptBuilderService.build_baseline
        AgentSpawnerService.call(evaluation, baseline_prompt, provider, config)
      end

      def run_context_agent(evaluation, skills, skill_context, provider, config)
        context_prompt = PromptBuilderService.build_context(evaluation, skills, skill_context)
        AgentSpawnerService.call(evaluation, context_prompt, provider, config)
      end

      def evaluate_and_record_trend(context)
        evaluation = context.evaluation
        provider = context.provider
        config = context.config

        criteria = evaluation.criteria
        judge_params = JudgeParamsBuilder.call(provider, config)

        result = Evaluation::Runner.call(
          task: evaluation.task,
          criteria: criteria,
          skill_context: context.skill_context,
          baseline_output: OutputFormatter.call(context.baseline_output),
          context_output: OutputFormatter.call(context.context_output),
          judge_params: judge_params
        )

        return enrich_error_result(result, evaluation, provider) unless result[:success]

        trend_result = TrendRecorderService.call(result, eval_name, skill_names)
        return enrich_error_result(trend_result, evaluation, provider) unless trend_result[:success]

        {
          success: true,
          eval_name: eval_name,
          skill_name: skill_names.join(', '),
          provider_name: provider.name,
          response: result[:response].merge(
            trend: trend_result[:trend],
            baseline_iterations: context.baseline_output[:iterations] || [],
            context_iterations: context.context_output[:iterations] || []
          )
        }
      end
    end
  end
end
