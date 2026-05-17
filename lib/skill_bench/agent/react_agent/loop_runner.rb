# frozen_string_literal: true

require_relative 'step'

module SkillBench
  module Agent
    class ReactAgent
      # Executes the ReAct loop iterations until completion or max iterations.
      class LoopRunner
        # Executes the loop.
        #
        # @param initial_prompt [String] The user task the agent must complete.
        # @param max_iterations [Integer] The maximum allowed steps before aborting.
        # @param config [Hash] The configuration for the Step execution.
        # @return [Hash] A result hash indicating success or failure.
        def self.call(initial_prompt, max_iterations, config)
          messages = [{ role: 'user', content: initial_prompt }]
          iterations_log = []
          step_count = 0

          while step_count < max_iterations
            step_count += 1

            step_result = Step.call(messages, config)
            iteration = step_result[:iteration]
            iterations_log << attach_step_number(iteration, step_count) if iteration

            unless step_result[:continue]
              final_result = step_result[:result] || { success: false, response: { error: { message: 'Step returned no result' } } }
              return merge_iterations(final_result, iterations_log)
            end

            messages = step_result[:messages]
          end

          merge_iterations(
            { success: false, response: { error: { message: Agent::ReactAgent::MAX_ITERATIONS_REACHED } } },
            iterations_log
          )
        rescue StandardError => e
          SkillBench::ErrorLogger.log_error(e, 'ReactAgent Error')
          merge_iterations(
            { success: false, response: { error: { message: e.message } } },
            iterations_log
          )
        end

        # Attaches the step number to an iteration hash.
        #
        # @param iteration [Hash] The iteration metadata from a Step.
        # @param step_count [Integer] The current step number.
        # @return [Hash] The iteration with :step_number added.
        def self.attach_step_number(iteration, step_count)
          iteration.merge(step_number: step_count)
        end

        # Merges the collected iterations into the result response.
        #
        # @param result [Hash] The final result hash from the loop.
        # @param iterations_log [Array<Hash>] Collected iteration metadata.
        # @return [Hash] The result with :iterations injected into :response.
        def self.merge_iterations(result, iterations_log)
          response = result[:response] || {}
          result.merge(response: response.merge(iterations: iterations_log))
        end
      end
    end
  end
end
