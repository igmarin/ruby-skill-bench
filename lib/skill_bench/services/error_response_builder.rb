# frozen_string_literal: true

module SkillBench
  module Services
    # Builds standardized error responses with metadata.
    class ErrorResponseBuilder
      # Builds a configuration error response.
      #
      # @param error [Exception] The configuration error
      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @param provider [Object] The resolved provider
      # @param skill_names [Array<String>] Names of the skills
      # @return [Hash] Error result with metadata
      def self.config_error(error, evaluation, provider, skill_names)
        new(evaluation, provider, skill_names).config_error(error)
      end

      # Builds an agent error response.
      #
      # @param result [Hash] The agent result containing the error
      # @param phase [String] The phase that failed (e.g., 'baseline', 'context')
      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @param provider [Object] The resolved provider
      # @param skill_names [Array<String>] Names of the skills
      # @return [Hash] Error result with metadata
      def self.agent_error(result, phase, evaluation, provider, skill_names)
        new(evaluation, provider, skill_names).agent_error(result, phase)
      end

      # Builds an empty context error response.
      #
      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @param provider [Object] The resolved provider
      # @param skill_names [Array<String>] Names of the skills
      # @return [Hash] Error result with metadata
      def self.empty_context_error(evaluation, provider, skill_names)
        new(evaluation, provider, skill_names).empty_context_error
      end

      # Enriches an existing error result with metadata.
      #
      # @param result [Hash] The existing error result
      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @param provider [Object] The resolved provider
      # @param skill_names [Array<String>] Names of the skills
      # @return [Hash] Enriched error result with metadata
      def self.enrich_error(result, evaluation, provider, skill_names)
        new(evaluation, provider, skill_names).enrich_error(result)
      end

      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @param provider [Object] The resolved provider
      # @param skill_names [Array<String>] Names of the skills
      def initialize(evaluation, provider, skill_names)
        @evaluation = evaluation
        @provider = provider
        @skill_names = skill_names
      end

      # Builds a configuration error response.
      #
      # @param error [Exception] The configuration error
      # @return [Hash] Error result with metadata
      def config_error(error)
        base_error_result("Configuration error: #{error.message}")
      end

      # Builds an agent error response.
      #
      # @param result [Hash] The agent result containing the error
      # @param phase [String] The phase that failed (e.g., 'baseline', 'context')
      # @return [Hash] Error result with metadata
      def agent_error(result, phase)
        raw = result[:raw_response]
        error_msg = raw&.dig(:response, :error, :message) || raw&.dig(:error, :message) || 'unknown error'
        base_error_result("#{phase.capitalize} agent failed: #{error_msg}")
      end

      # Builds an empty context error response.
      #
      # @return [Hash] Error result with metadata
      def empty_context_error
        base_error_result('Skill context is empty. Ensure SKILL.md exists and has content.')
      end

      # Enriches an existing error result with metadata.
      #
      # @param result [Hash] The existing error result
      # @return [Hash] Enriched error result with metadata
      def enrich_error(result)
        result.merge(
          eval_name: @evaluation.name,
          skill_name: @skill_names.join(', '),
          provider_name: @provider.name
        )
      end

      private

      # Builds a base error result with metadata.
      #
      # @param message [String] The error message
      # @return [Hash] Error result with metadata
      def base_error_result(message)
        {
          success: false,
          response: {
            error: {
              message: message
            }
          },
          eval_name: @evaluation.name,
          skill_name: @skill_names.join(', '),
          provider_name: @provider.name
        }
      end
    end
  end
end
