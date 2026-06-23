# frozen_string_literal: true

require 'faraday'
require_relative '../constants'

module SkillBench
  module Clients
    # Builds and executes HTTP requests to LLM provider APIs.
    # Encapsulates Faraday connection setup and request execution.
    class RequestBuilder
      # Creates a Faraday connection with JSON middleware.
      #
      # @param base_url [String] The API base URL
      # @param open_timeout [Integer] Connection open timeout in seconds
      # @param timeout [Integer] Request timeout in seconds
      # @return [Faraday::Connection] Configured Faraday connection
      def self.build_connection(base_url, open_timeout: Constants::HttpClient::DEFAULT_OPEN_TIMEOUT, timeout: Constants::HttpClient::DEFAULT_TIMEOUT)
        Faraday.new(url: base_url) do |f|
          f.request :json
          f.response :json
          f.options.open_timeout = open_timeout
          f.options.timeout = timeout
        end
      end

      # Executes a POST request to the LLM API.
      #
      # @param connection [Faraday::Connection] The Faraday connection
      # @param path [String] The request path
      # @param headers [Hash] Request headers
      # @param body [Hash] Request body
      # @return [Faraday::Response] The HTTP response
      def self.execute(connection, path, headers:, body:)
        connection.post(path) do |req|
          req.headers.update(headers)
          req.body = body.to_json
        end
      end
    end
  end
end
