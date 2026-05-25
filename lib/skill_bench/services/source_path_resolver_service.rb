# frozen_string_literal: true

require_relative '../execution/source_path_resolver'

module SkillBench
  module Services
    # Resolves the source path for context hydration.
    class SourcePathResolverService
      # Resolves the source path for context hydration.
      #
      # Tries the eval's `source/` subdirectory first, then falls back to
      # SourcePathResolver inference.
      #
      # @param evaluation [SkillBench::Models::Eval] The eval being run
      # @return [String, nil] The resolved source path, or nil if not found
      def self.call(evaluation)
        new(evaluation).call
      end

      # @param evaluation [SkillBench::Models::Eval] The eval being run
      def initialize(evaluation)
        @evaluation = evaluation
      end

      # Resolves the source path for context hydration.
      #
      # Tries the eval's `source/` subdirectory first, then falls back to
      # SourcePathResolver inference.
      #
      # @return [String, nil] The resolved source path, or nil if not found
      def call
        eval_path = @evaluation.path
        eval_source = File.join(eval_path, 'source')
        return eval_source if Dir.exist?(eval_source)

        sources = SkillBench::Config.skill_sources || {}
        inferred = Execution::SourcePathResolver.call(
          eval_folder_path: eval_path.to_s,
          skill_sources: sources
        )
        inferred if inferred && Dir.exist?(inferred)
      end
    end
  end
end
