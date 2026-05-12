# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module SkillBench
  module Clients
    module Providers
      # OpenCode provider client.
      #
      # IMPORTANT: OpenCode does not host a public LLM API. This provider is a
      # thin wrapper around an OpenAI-compatible endpoint that YOU provide (e.g.
      # LiteLLM proxy, vLLM, or a company gateway). You MUST set `base_url` in
      # `skill-bench.json` or via the `SKILL_BENCH_OPENCODE_BASE_URL` environment
      # variable, otherwise the provider will fail with "Base URL not set for Opencode".
      class OpenCode < BaseClient
        SkillBench::Clients::ProviderRegistry.register(:opencode, self)

        # Returns the provider identifier.
        #
        # @return [Symbol]
        def provider_name
          :opencode
        end

        protected

        # Returns the base URL for OpenCode API.
        # OpenCode does not host a public LLM endpoint; users must configure
        # a custom base_url (e.g. a self-hosted OpenAI-compatible proxy).
        #
        # @return [String]
        def base_url
          @base_url_config
        end

        # Returns the request path for chat completions.
        #
        # @return [String]
        def request_path
          @request_path_config || '/v1/chat/completions'
        end

        private

        # @return [Array<String>]
        def missing_config_keys
          missing = []
          missing << 'API Key' if @api_key.nil? || @api_key.empty?
          missing << 'Base URL' if @base_url_config.nil? || @base_url_config.to_s.empty?
          missing
        end
      end
    end
  end
end
