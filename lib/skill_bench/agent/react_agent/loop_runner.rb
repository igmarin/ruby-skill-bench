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
          total_usage = empty_usage
          step_count = 0

          while step_count < max_iterations
            step_count += 1

            step_result = Step.call(messages, config)
            iteration = step_result[:iteration]
            iterations_log << attach_step_number(iteration, step_count) if iteration
            total_usage = add_usage(total_usage, step_result[:usage])

            unless step_result[:continue]
              final_result = step_result[:result] || { success: false, response: { error: { message: 'Step returned no result' } } }
              return finalize(final_result, iterations_log, total_usage)
            end

            messages = step_result[:messages]
          end

          finalize(
            { success: false, response: { error: { message: Agent::ReactAgent::MAX_ITERATIONS_REACHED } } },
            iterations_log,
            total_usage
          )
        rescue StandardError => e
          SkillBench::ErrorLogger.log_error(e, 'ReactAgent Error')
          finalize(
            { success: false, response: { error: { message: e.message } } },
            iterations_log,
            total_usage
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

        # Merges the collected iterations and accumulated usage into the response.
        #
        # @param result [Hash] The final result hash from the loop.
        # @param iterations_log [Array<Hash>] Collected iteration metadata.
        # @param total_usage [Hash] Summed token usage across all iterations.
        # @return [Hash] The result with :iterations and :usage injected into :response.
        def self.finalize(result, iterations_log, total_usage)
          response = result[:response] || {}
          result.merge(response: response.merge(iterations: iterations_log, usage: total_usage))
        end

        # A zeroed token-usage accumulator.
        #
        # @return [Hash] Usage hash with prompt/completion/total token counts set to zero.
        def self.empty_usage
          { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 }
        end

        # Adds a single step's usage onto a running total.
        #
        # @param total [Hash] The running usage total.
        # @param usage [Hash, nil] A step's usage hash (may be nil or empty).
        # @return [Hash] A new summed usage hash.
        def self.add_usage(total, usage)
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
        def self.token_count(usage, key)
          (usage[key] || usage[key.to_s] || 0).to_i
        end
      end
    end
  end
end
