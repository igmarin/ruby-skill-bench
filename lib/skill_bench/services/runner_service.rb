# frozen_string_literal: true

require_relative '../models/eval'
require_relative '../models/skill'
require_relative '../models/config'
require_relative '../clients/all'
require_relative 'scoring_service'
require_relative 'skill_resolver'

module SkillBench
  module Services
    # Orchestrates the execution of an eval
    class RunnerService
      # Runs an eval with the given parameters.
      #
      # @param eval_name [String] Name or path of the eval to run
      # @param skill_name [String] Name of the skill to use
      # @param provider_name [String] Name of the provider to use
      # @return [Hash] Result with pass/fail and score
      def self.call(eval_name:, skill_name:, provider_name:)
        new(eval_name: eval_name, skill_name: skill_name, provider_name: provider_name).call
      end

      # @param eval_name [String] Name or path of the eval
      # @param skill_name [String] Name of the skill
      # @param provider_name [String] Name of the provider
      def initialize(eval_name:, skill_name:, provider_name:)
        @eval_name = eval_name
        @skill_name = skill_name
        @provider_name = provider_name
      end

      # Executes the eval: resolves entities, spawns agent, scores result.
      #
      # @return [Hash] Scored result with pass/fail status
      def call
        eval = resolve_eval
        skill = resolve_skill
        provider = resolve_provider

        result = spawn_agent(eval, skill, provider)
        score_result(eval, result)
      end

      private

      attr_reader :eval_name, :skill_name, :provider_name

      def resolve_eval
        eval_path = eval_name.include?('/') ? eval_name : "evals/#{eval_name}"
        SkillBench::Models::Eval.load(eval_path)
      end

      def resolve_skill
        Services::SkillResolver.call(skill_name)
      end

      def resolve_provider
        return mock_provider if provider_name == 'mock'

        config = SkillBench::Models::Config.load
        config.find_provider(provider_name) || raise("Provider not found: #{provider_name}")
      end

      def mock_provider
        Struct.new(:name, :runtime, :llm).new('mock', 'mock', 'mock')
      end

      def spawn_agent(eval, skill, provider)
        return { result: 'mock result', status: 'success' } if provider.name == 'mock'

        client_class = SkillBench::Clients::ProviderRegistry.for(provider.runtime)
        config = provider.merged_config

        # Standardize options for the client
        options = config.dup
        options[:model] ||= provider.llm

        # Execute the prompt
        response = client_class.call(
          system_prompt: load_skill_context(skill),
          messages: [{ role: 'user', content: eval.task }],
          **options
        )

        # Standardize output for AgentEval
        {
          result: response[:result],
          status: response[:success] ? 'success' : 'error',
          runtime: provider.runtime,
          usage: response[:usage],
          raw_response: response[:response]
        }
      end

      def load_skill_context(skill)
        skill_md = File.join(skill.path, 'SKILL.md')
        File.exist?(skill_md) ? File.read(skill_md) : ''
      end

      def score_result(eval, result)
        ScoringService.call(
          eval: eval,
          result: result,
          skill_name: skill_name,
          provider_name: provider_name
        )
      end
    end
  end
end
