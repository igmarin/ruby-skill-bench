# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module Evaluator
  module Clients
    module Providers
      # LangChain-specific LLM client placeholder.
      class Langchain < BaseClient
        Evaluator::Clients::ProviderRegistry.register(:langchain, self)

        def call
          {
            success: true,
            result: 'LangChain processing (placeholder)',
            status: 'success',
            response: {},
            usage: {}
          }
        end
      end
    end
  end
end
