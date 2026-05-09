# frozen_string_literal: true

module SkillBench
  # Value object capturing sandbox execution metadata.
  #
  # Holds files changed, commands run, and agent reasoning extracted
  # from an evaluation run for delivery to the judge.
  class AgentSummary
    attr_reader :files_changed, :commands_run, :agent_reasoning

    # Creates an AgentSummary from execution data.
    #
    # @param files_changed [Array<String>] List of file paths modified.
    # @param commands_run [Array<String>] List of shell commands executed.
    # @param agent_reasoning [String] Excerpt of agent reasoning.
    # @return [Hash] Service response with agent_summary or error.
    def self.call(files_changed: [], commands_run: [], agent_reasoning: '')
      new(files_changed:, commands_run:, agent_reasoning:).call
    end

    # @param files_changed [Array<String>] Modified file paths.
    # @param commands_run [Array<String>] Executed commands.
    # @param agent_reasoning [String] Agent reasoning excerpt.
    def initialize(files_changed:, commands_run:, agent_reasoning:)
      @files_changed = files_changed
      @commands_run = commands_run
      @agent_reasoning = agent_reasoning
    end

    # Returns the agent summary in the service response format.
    #
    # @return [Hash] Service response with agent_summary.
    def call
      { success: true, response: { agent_summary: self } }
    end
  end
end
