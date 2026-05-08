# frozen_string_literal: true

require 'json'
require_relative '../models/eval'
require_relative '../models/skill'
require_relative '../models/config'
require_relative '../models/provider'
require_relative '../clients/all'
require_relative 'scoring_service'
require_relative 'skill_resolver'

module SkillBench
  module Services
    # Orchestrates the execution of an eval
    class RunnerService
      # Mock provider struct for testing without real LLM calls.
      MOCK_PROVIDER = Struct.new(:name, :runtime, :llm, :merged_config)
      private_constant :MOCK_PROVIDER
      # Runs an eval with the given parameters.
      #
      # @param eval_name [String] Name or path of the eval to run
      # @param skill_name [String] Name of the skill to use
      # @return [Hash] Result with pass/fail and score
      def self.call(eval_name:, skill_name:)
        new(eval_name: eval_name, skill_name: skill_name).call
      end

      # @param eval_name [String] Name or path of the eval
      # @param skill_name [String] Name of the skill
      def initialize(eval_name:, skill_name:)
        @eval_name = eval_name
        @skill_name = skill_name
      end

      # Executes the eval: resolves entities, spawns agent, scores result.
      #
      # @return [Hash] Scored result with pass/fail status
      def call
        evaluation = resolve_eval
        skill = resolve_skill
        provider = resolve_provider

        result = spawn_agent(evaluation, skill, provider)
        score_result(evaluation, result)
      end

      private

      attr_reader :eval_name, :skill_name

      def resolve_eval
        eval_path = eval_name.include?('/') ? eval_name : "evals/#{eval_name}"
        SkillBench::Models::Eval.load(eval_path)
      end

      def resolve_skill
        Services::SkillResolver.call(skill_name)
      end

      def resolve_provider
        config = SkillBench::Models::Config.load
        provider = config.to_provider
        return provider if provider

        warn 'Config load failed, using mock provider'
        MOCK_PROVIDER.new('mock', 'mock', 'mock', {})
      end

      def spawn_agent(evaluation, skill, provider)
        return { result: 'mock result', status: :success } if provider.name == 'mock'

        client_class = SkillBench::Clients::ProviderRegistry.for(provider.runtime.to_sym)
        config = provider.merged_config

        # Standardize options for the client
        options = config.dup
        options[:model] ||= provider.llm

        # Execute the prompt
        response = client_class.call(
          system_prompt: load_skill_context(skill),
          messages: [{ role: 'user', content: evaluation.task }],
          **options
        )

        # Standardize output for SkillBench
        {
          result: response[:result],
          status: response[:success] ? :success : :error,
          runtime: provider.runtime,
          usage: response[:usage],
          raw_response: response[:response]
        }
      end

      def load_skill_context(skill)
        skill_md = File.join(skill.path, 'SKILL.md')
        File.exist?(skill_md) ? File.read(skill_md) : ''
      end

      def score_result(evaluation, result)
        ScoringService.call(
          eval: evaluation,
          result: result,
          skill_name: skill_name,
          provider_name: resolve_provider_name
        )
      end

      def resolve_provider_name
        resolve_provider.name.to_s
      end
    end
  end
end
