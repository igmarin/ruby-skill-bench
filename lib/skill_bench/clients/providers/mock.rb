# frozen_string_literal: true

require_relative '../provider_registry'
require 'json'

module SkillBench
  module Clients
    module Providers
      # Mock LLM client for testing and local validation.
      class Mock
        SkillBench::Clients::ProviderRegistry.register(:mock, self)

        def self.call(system_prompt:, messages:, **_options)
          prompt = messages.first[:content] || messages.first['content'] || ''
          
          # Parse dimensions from prompt
          dimensions = {}
          prompt.scan(/-\s+([^:]+):\s+max_score=(\d+)/).each do |name, max_score|
            max = max_score.to_i
            # Give baseline slightly lower score than context to simulate improvement
            is_context = prompt.match?(/## Skill Context\s+\S+/)
            score = is_context ? (max * 0.95).round : (max * 0.8).round
            dimensions[name] = {
              'score' => score,
              'max_score' => max,
              'reasoning' => "Mock evaluation for #{name}"
            }
          end
          
          if dimensions.empty?
            dimensions['correctness'] = { 'score' => 8, 'max_score' => 10, 'reasoning' => 'Mock correctness' }
          end
          
          content = {
            'dimensions' => dimensions,
            'overall_reasoning' => 'Mock evaluation overall reasoning'
          }.to_json
          
          {
            success: true,
            response: {
              message: {
                content: content
              }
            }
          }
        end
      end
    end
  end
end
