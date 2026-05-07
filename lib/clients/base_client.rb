# frozen_string_literal: true

require 'faraday'
require 'json'
require_relative '../config'
require_relative 'provider_config'

module Evaluator
  module Clients
    # Base class for all LLM provider clients.
    # Implements common Faraday logic, response handling, and error logging.
    # Following the Template Method pattern and ruby-service-objects standards.
    class BaseClient
      API_FAILED = 'API Request failed'

      attr_reader :messages, :system_prompt, :tools, :api_key, :model, :options

      # Standard entry point for the service object.
      #
      # @param system_prompt [String] The system instruction for the LLM.
      # @param messages [Array<Hash>] The list of conversation messages.
      # @param tools [Array<Hash>] (optional) Array of tool definitions.
      # @param options [Hash] (optional) Additional provider-specific options.
      # @return [Hash] with :success [Boolean] and :response [Hash] keys.
      def self.call(system_prompt:, messages:, tools: [], **options)
        new(system_prompt: system_prompt, messages: messages, tools: tools, **options).call
      end

      # Initializes the client with validated parameters.
      # @param options [Hash] Configuration overrides.
      def initialize(options = {})
        config = ProviderConfig.call(provider: provider_name, options: options)

        @api_key = config[:api_key]
        @model = config[:model]
        @base_url_config = config[:base_url]
        @request_path_config = config[:request_path]
        @provider_display_name = config[:provider_name]

        # Provider-specific extras (nil when not used by the provider)
        @location = config[:location]
        @project_id = config[:project_id]
        @endpoint = config[:endpoint]
        @api_version = config[:api_version]

        @system_prompt = options[:system_prompt] || ''
        @messages = options[:messages] || []
        @tools = options[:tools] || []
      end

      # Abstract method to return the provider identifier.
      #
      # @return [Symbol]
      def provider_name
        raise NotImplementedError, "#{self.class} must implement #provider_name"
      end

      # Sends the request to the LLM and returns the standardized response.
      #
      # @return [Hash] standardized response with success, body, and usage information.
      def call
        return config_error unless valid_config?

        response = execute_request
        handle_response(response)
      rescue Faraday::Error => e
        handle_exception(e, 'Network Error')
      rescue JSON::ParserError => e
        handle_exception(e, 'Parsing Error')
      rescue StandardError => e
        handle_exception(e, 'Unexpected Error')
      end

      protected

      # Returns the base URL for the LLM API.
      #
      # @return [String]
      def base_url
        @base_url_config || raise(NotImplementedError, "#{self.class} must implement #base_url")
      end

      # Returns the request path for the LLM API.
      #
      # @return [String]
      def request_path
        @request_path_config || raise(NotImplementedError, "#{self.class} must implement #request_path")
      end

      # @return [Hash]
      def request_headers
        {
          'Authorization' => "Bearer #{@api_key}",
          'Content-Type' => 'application/json'
        }
      end

      # @return [Hash]
      def request_body
        body = {
          model: model_name,
          messages: [{ role: 'system', content: @system_prompt }] + @messages
        }
        body[:tools] = @tools if @tools&.any?
        body
      end

      # @return [String]
      def model_name
        @model
      end

      # Validates that the configuration is complete.
      #
      # @return [Boolean]
      def valid_config?
        missing_config_keys.empty?
      end

      # Returns the list of configuration keys that are required but missing.
      #
      # @return [Array<String>]
      def missing_config_keys
        missing = []
        missing << 'API Key' if @api_key.nil? || @api_key.empty?
        missing
      end

      # Standardized error response when configuration is missing.
      #
      # @return [Hash]
      def config_error
        missing = missing_config_keys
        message = if missing.length > 1
                    "#{missing[0...-1].join(', ')}, and #{missing[-1]} not set for #{@provider_display_name}"
                  else
                    "#{missing.first} not set for #{@provider_display_name}"
                  end
        { success: false, response: { error: { message: message } }, result: message, status: 'error' }
      end

      # Extracts the message hash from the provider's specific response body structure.
      # Default implementation for OpenAI-compatible providers.
      #
      # @param body [Hash]
      # @return [Hash, nil]
      def extract_message(body)
        choices = body[:choices] || body['choices']
        return nil unless choices&.any?

        choices.first[:message] || choices.first['message']
      end

      # Extracts token usage from the provider-specific response.
      # @param body [Hash]
      # @return [Hash]
      def extract_usage(body)
        body[:usage] || body['usage'] || {}
      end

      private

      def execute_request
        conn = Faraday.new(url: base_url) do |f|
          f.request :json
          f.response :json
          f.options.open_timeout = 5
          f.options.timeout = 10
        end

        conn.post(request_path) do |req|
          req.headers.update(request_headers)
          req.body = request_body.to_json
        end
      end

      def handle_response(response)
        parsed = parse_response_body(response)
        return failure_response(response, parsed) unless response.success?

        message = extract_message(parsed)
        return missing_message_response(response, parsed) unless valid_message?(message)

        success_response(parsed, message)
      end

      def parse_response_body(response)
        response.body.is_a?(Hash) ? response.body : JSON.parse(response.body, symbolize_names: true)
      rescue JSON::ParserError
        { error: { message: response.body.to_s } }
      end

      def valid_message?(message)
        return false if message.nil?

        content = message.is_a?(Hash) ? (message[:content] || message['content']) : message
        tool_calls = message.is_a?(Hash) ? (message[:tool_calls] || message['tool_calls']) : nil

        !content.nil? || (tool_calls && !tool_calls.empty?)
      end

      def success_response(parsed, message)
        content = message.is_a?(Hash) ? (message[:content] || message['content']) : message
        {
          success: true,
          result: content,
          usage: extract_usage(parsed),
          response: parsed.merge(message: message),
          status: 'success'
        }
      end

      def failure_response(response, parsed)
        error_msg = "#{API_FAILED}: #{response.status}"
        detail = parsed.is_a?(Hash) ? (parsed[:error] || parsed['error'] || parsed) : parsed

        if detail.is_a?(Hash) && (detail[:message] || detail['message'])
          error_msg += " - #{detail[:message] || detail['message']}"
        elsif !detail.to_s.empty?
          error_msg += " - #{detail}"
        end

        {
          success: false,
          result: error_msg,
          usage: extract_usage(parsed),
          response: { error: { message: error_msg } },
          status: 'error',
          code: response.status
        }
      end

      def missing_message_response(response, parsed)
        error_msg = 'LLM response missing message content'
        {
          success: false,
          result: error_msg,
          usage: extract_usage(parsed),
          response: { error: { message: error_msg } },
          status: 'error',
          code: response.status
        }
      end

      def handle_exception(error, type)
        log_error(error)
        { success: false, result: "#{type}: #{error.message}", status: 'error' }
      end

      def log_error(error)
        message = "#{self.class.name} Error: #{error.message}"
        backtrace = error.backtrace.first(5).join("\n")

        logger = defined?(Rails) ? Rails.logger : nil
        if logger
          logger.error(message)
          logger.error(backtrace)
        else
          warn(message)
          warn(backtrace)
        end
      end
    end
  end
end
