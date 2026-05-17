# frozen_string_literal: true

require_relative 'formatting_helpers'

module SkillBench
  module Services
    # Formats ReAct loop iteration timelines for human-readable output.
    class IterationFormatter
      extend FormattingHelpers

      # Formats an iteration timeline section.
      #
      # @param title [String] Section title.
      # @param iterations [Array<Hash>] Iteration metadata with keys :step_number,
      #   :thought, :tools_used, :observation_summary.
      # @return [String] Formatted section.
      def self.format(title, iterations)
        lines = ["  === #{title} ==="]
        iterations.each do |iter|
          tools = iter[:tools_used] || []
          tool_str = tools.empty? ? '' : " → Tool: #{tools.join(', ')}"
          observation = iter[:observation_summary].to_s
          observation_str = observation.empty? ? '' : " → Observation: #{truncate(observation, 60)}"
          lines << "  Step #{iter[:step_number]}: #{iter[:thought]}#{tool_str}#{observation_str}"
        end
        lines.join("\n")
      end
    end
  end
end
