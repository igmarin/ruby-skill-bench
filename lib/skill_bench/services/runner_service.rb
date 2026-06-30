# frozen_string_literal: true

require 'parallel'
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
require_relative 'cost_calculator'
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

        skill_context = ContextLoaderService.call(skills)
        return empty_context_error_result(evaluation, provider) if skill_context.strip.empty?

        baseline_output, context_output = run_agents_concurrently(evaluation, skills, skill_context, provider, config)
        return agent_error_result(baseline_output, 'baseline', evaluation, provider) if baseline_output[:status] == :error
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

      # Runs the baseline and context agents concurrently.
      #
      # The two runs are independent: each spawns its own `Dir.mktmpdir`
      # sandbox and uses a per-call client, and neither reads the other's
      # state. The work is I/O-bound (HTTP + subprocess), so threads release
      # the GIL and the agent phase is bound by the slower run instead of the
      # sum of both. The skill context is built once by the caller and passed
      # in, so no skill-dependent work is duplicated or moved into the baseline.
      #
      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @param skills [Array<SkillBench::Models::Skill>] Resolved skills
      # @param skill_context [String] Combined skill context, built once pre-fork
      # @param provider [Object] The resolved provider
      # @param config [Hash, nil] Provider config
      # @return [Array(Hash, Hash)] Baseline and context outputs, in that order
      def run_agents_concurrently(evaluation, skills, skill_context, provider, config)
        runs = [
          -> { run_baseline_agent(evaluation, provider, config) },
          -> { run_context_agent(evaluation, skills, skill_context, provider, config) }
        ]
        Parallel.map(runs, in_threads: runs.size, &:call)
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

        tokens = aggregate_usage(context.baseline_output, context.context_output)
        cost = CostCalculator.call(usage: tokens, model: agent_model(config, provider))

        {
          success: true,
          eval_name: eval_name,
          skill_name: skill_names.join(', '),
          provider_name: provider.name,
          tokens: tokens,
          cost: cost,
          response: result[:response].merge(
            trend: trend_result[:trend],
            baseline_iterations: context.baseline_output[:iterations] || [],
            context_iterations: context.context_output[:iterations] || []
          )
        }
      end

      # Sums the token usage of the baseline and context agent runs.
      #
      # Judge-side usage is not yet threaded through (the judge lives under the
      # untouched `clients/` boundary), so this is scoped to agent usage.
      #
      # @param baseline_output [Hash] The baseline agent output (carries :usage).
      # @param context_output [Hash] The context agent output (carries :usage).
      # @return [Hash] Combined prompt/completion/total token counts.
      def aggregate_usage(baseline_output, context_output)
        add_usage(
          add_usage(empty_usage, baseline_output[:usage]),
          context_output[:usage]
        )
      end

      # A zeroed token-usage accumulator.
      #
      # @return [Hash] Usage hash with prompt/completion/total token counts set to zero.
      def empty_usage
        { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 }
      end

      # Adds one usage hash onto a running total.
      #
      # @param total [Hash] The running usage total.
      # @param usage [Hash, nil] A run's usage hash (may be nil or empty).
      # @return [Hash] A new summed usage hash.
      def add_usage(total, usage)
        usage ||= {}
        {
          prompt_tokens: total[:prompt_tokens] + token_count(usage, :prompt_tokens),
          completion_tokens: total[:completion_tokens] + token_count(usage, :completion_tokens),
          total_tokens: total[:total_tokens] + token_count(usage, :total_tokens)
        }
      end

      # Reads a token count from a usage hash, tolerating string keys.
      #
      # @param usage [Hash] The usage hash.
      # @param key [Symbol] The usage key (e.g. :prompt_tokens).
      # @return [Integer] The token count, or zero when absent.
      def token_count(usage, key)
        (usage[key] || usage[key.to_s] || 0).to_i
      end

      # Resolves the model name used for pricing from config, falling back to the provider LLM.
      #
      # @param config [Hash, nil] Provider config.
      # @param provider [Object] The resolved provider.
      # @return [String] The model name (e.g. "gpt-4o").
      def agent_model(config, provider)
        return provider.llm unless config.is_a?(Hash)

        config[:model] || config['model'] || provider.llm
      end
    end
  end
end
