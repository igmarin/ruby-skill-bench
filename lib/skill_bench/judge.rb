# frozen_string_literal: true

require 'securerandom'
require_relative 'client'

module SkillBench
  # Responsible for evaluating AI-generated code modifications.
  # Compares baseline and context-hydrated diffs against given criteria.
  class Judge
    # Evaluates two code diffs against a specific task and criteria.
    #
    # @param task_content [String] The description of the task to be completed.
    # @param criteria_content [String] The criteria used for scoring the solutions.
    # @param baseline_diff [String] The diff generated without context.
    # @param context_diff [String] The diff generated with context.
    # @param client_params [Hash] Optional parameters to pass to the client.
    # @return [Hash] with :success [Boolean] and :response containing scores or error.
    def self.call(task_content, criteria_content, baseline_diff, context_diff, client_params = {})
      new(task_content, criteria_content, baseline_diff, context_diff, client_params).call
    end

    # @param task_content [String] The description of the task to be completed.
    # @param criteria_content [String] The criteria used for scoring the solutions.
    # @param baseline_diff [String] The diff generated without context.
    # @param context_diff [String] The diff generated with context.
    # @param client_params [Hash] Optional parameters to pass to the client.
    def initialize(task_content, criteria_content, baseline_diff, context_diff, client_params)
      @task_content = task_content
      @criteria_content = criteria_content
      @baseline_diff = baseline_diff
      @context_diff = context_diff
      @client_params = client_params
    end

    # Executes the evaluation process via the LLM client.
    #
    # @return [Hash] with :success [Boolean] and :response containing JSON string or error.
    def call
      system_prompt = 'You are an objective judge evaluating AI coding models. Your goal is to score responses based strictly on the provided criteria.'

      delim = "___SKILLBENCH_DELIM_#{SecureRandom.hex(8)}___"

      prompt = build_prompt(delim)

      judge_result = Client.call(
        system_prompt: system_prompt,
        messages: [{ role: 'user', content: prompt }],
        **@client_params
      )

      return judge_result unless judge_result[:success]

      response = judge_result[:response]
      message = response[:message] || response['message']
      content = message.is_a?(Hash) ? (message[:content] || message['content']) : nil

      return { success: false, response: { error: { message: 'Empty response from judge' } } } unless content

      { success: true, response: { content: content } }
    end

    private

    def build_prompt(delim)
      <<~PROMPT
        You need to evaluate two AI codebase modifications against a set of criteria.

        #{delim}TASK#{delim}
        #{escape_prompt_content(@task_content, delim)}
        #{delim}END_TASK#{delim}

        #{delim}CRITERIA#{delim}
        #{escape_prompt_content(@criteria_content, delim)}
        #{delim}END_CRITERIA#{delim}

        #{delim}BASELINE#{delim}
        #{escape_prompt_content(@baseline_diff, delim)}
        #{delim}END_BASELINE#{delim}

        #{delim}CONTEXT#{delim}
        #{escape_prompt_content(@context_diff, delim)}
        #{delim}END_CONTEXT#{delim}

        Please analyze both code diffs. Did they fulfill the criteria?
        Did the context diff follow any specific instructions better?
        Provide a final score out of 100 for each, and explain why.
        Output your response as JSON with format:
        {
          "baseline_score": number,
          "context_score": number,
          "reasoning": "..."
        }
      PROMPT
    end

    def escape_prompt_content(content, delim)
      content.to_s.gsub(delim, '[DELIM]').gsub(%r{</}, '<\\/')
    end
  end
end
