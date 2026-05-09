# frozen_string_literal: true

require 'securerandom'
require_relative 'client'

module SkillBench
  # Responsible for evaluating AI-generated code modifications.
  #
  # Accepts a structured judge prompt, calls the LLM client,
  # and parses the response into a JudgeResponse with per-dimension scores.
  class Judge
    SYSTEM_PROMPT = 'You are an objective judge evaluating AI coding models. ' \
                    'Your goal is to score responses based strictly on the provided criteria. ' \
                    'Return only valid JSON.'

    # Evaluates agent output via the LLM judge.
    #
    # @param prompt [String] The structured judge prompt.
    # @param client_params [Hash] Optional parameters to pass to the client.
    # @return [Hash] with :success [Boolean] and :response containing JudgeResponse or error.
    def self.call(prompt:, client_params: {})
      new(prompt:, client_params:).call
    end

    # @param prompt [String] The structured judge prompt.
    # @param client_params [Hash] Optional client parameters.
    def initialize(prompt:, client_params:)
      @prompt = prompt
      @client_params = client_params
    end

    # Executes the evaluation process via the LLM client.
    #
    # @return [Hash] Service response with JudgeResponse or error.
    def call
      judge_result = Client.call(
        system_prompt: SYSTEM_PROMPT,
        messages: [{ role: 'user', content: prompt }],
        **client_params
      )

      return judge_result unless judge_result[:success]

      content = extract_content(judge_result)
      return empty_response_result unless content

      JudgeResponse.call(json: content)
    rescue StandardError => e
      SkillBench::ErrorLogger.log_error(e, 'Judge Evaluation Error')
      { success: false, response: { error: { message: e.message } } }
    end

    private

    attr_reader :prompt, :client_params

    def extract_content(judge_result)
      response = judge_result[:response]
      message = response[:message] || response['message']
      return nil unless message.is_a?(Hash)

      message[:content] || message['content']
    end

    def empty_response_result
      { success: false, response: { error: { message: 'Empty response from judge' } } }
    end
  end
end
