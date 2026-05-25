# frozen_string_literal: true

require_relative '../models/eval'

module SkillBench
  module Services
    # Resolves an eval from a name or path.
    class EvalResolver
      # Resolves an eval from a name or path.
      #
      # @param eval_name [String] Name or path of the eval to resolve
      # @return [SkillBench::Models::Eval] The resolved eval
      # @raise [Errno::ENOENT] when the eval directory does not exist
      def self.call(eval_name)
        new(eval_name).call
      end

      # @param eval_name [String] Name or path of the eval
      def initialize(eval_name)
        @eval_name = eval_name
      end

      # Resolves the eval from the name or path.
      #
      # @return [SkillBench::Models::Eval] The resolved eval
      # @raise [Errno::ENOENT] when the eval directory does not exist
      def call
        eval_path = @eval_name.include?('/') ? @eval_name : "evals/#{@eval_name}"
        SkillBench::Models::Eval.load(eval_path)
      end
    end
  end
end
