# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module SkillBench
  module Clients
    module Providers
      # Amazon Bedrock LLM client.
      # Uses Bedrock Runtime's OpenAI-compatible Chat Completions path with a
      # Bedrock API key (bearer). IAM SigV4 signing is a follow-up.
      class Bedrock < BaseClient
        SkillBench::Clients::ProviderRegistry.register(:bedrock, self)

        DEFAULT_REGION = 'us-east-1'

        # Returns the provider identifier.
        #
        # @return [Symbol]
        def provider_name
          :bedrock
        end

        protected

        # Returns the Bedrock Runtime host for the configured region.
        #
        # @return [String]
        def base_url
          @base_url_config || "https://bedrock-runtime.#{region}.amazonaws.com"
        end

        # Returns the OpenAI-compatible chat completions path.
        #
        # @return [String]
        def request_path
          @request_path_config || '/openai/v1/chat/completions'
        end

        private

        def region
          loc = @location.to_s.strip
          loc.empty? ? DEFAULT_REGION : loc
        end
      end
    end
  end
end
