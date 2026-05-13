# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative '../services/skill_resolver'
require_relative '../error_logger'
require_relative '../models/config'
require_relative '../models/criteria_validator'

module SkillBench
  module Evaluation
    # Generates an eval (task.md + criteria.json) from a skill's documentation.
    class Generator
      # Prompt template used to generate evals from skill documentation via LLM.
      GENERATION_PROMPT = <<~PROMPT
        You are an evaluation designer for a skill-benchmarking tool.

        Given a skill's documentation, create an eval scenario that tests whether an AI agent
        can apply the skill correctly. Output ONLY a JSON object with this exact structure:

        {
          "task": "A detailed task description for the agent to perform. Be specific about what the agent should build or do.",
          "context": "A brief description of what this eval measures.",
          "dimensions": [
            { "name": "correctness", "max_score": 30 },
            { "name": "skill_adherence", "max_score": 25 },
            { "name": "code_quality", "max_score": 20 },
            { "name": "test_coverage", "max_score": 15 },
            { "name": "documentation", "max_score": 10 }
          ],
          "pass_threshold": 70,
          "minimum_delta": 10
        }

        Rules:
        - dimension max_scores MUST sum to exactly 100
        - pass_threshold should be between 60 and 80
        - minimum_delta should be between 5 and 15
        - task should be specific enough that an agent can attempt it in under 5 minutes
        - the eval should test whether the agent follows the patterns from the skill

        Skill documentation:
      PROMPT

      # @param skill_name [String] Name of the skill to base the eval on.
      # @param eval_name [String] Name for the new eval directory.
      def initialize(skill_name:, eval_name:)
        @skill_name = skill_name
        @eval_name = eval_name
      end

      # Generates the eval files.
      #
      # @return [Hash] Service response.
      def call
        sanitized = sanitize_eval_name(eval_name)
        return invalid_name_result unless sanitized

        skill = resolve_skill
        return skill_not_found_result unless skill

        skill_content = read_skill_content(skill.path)
        generated = generate_eval(skill_content)
        return generated unless generated[:success]

        write_eval_files(sanitized, generated[:response][:data])

        criteria_path = File.join('evals', sanitized, 'criteria.json')
        validation = SkillBench::Models::CriteriaValidator.call(path: criteria_path)
        unless validation[:success]
          FileUtils.rm_rf(File.join('evals', sanitized))
          return validation
        end

        { success: true, response: { eval_path: "evals/#{sanitized}" } }
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'Evaluation::Generator Error')
        { success: false, response: { error: { message: e.message } } }
      end

      private

      attr_reader :skill_name, :eval_name

      def sanitize_eval_name(name)
        stripped = name&.strip
        return nil if stripped.nil? || stripped.empty?
        return nil if stripped == '.'
        return nil if stripped.include?('..') || stripped.start_with?('/') || stripped =~ %r{[\\/:]}

        stripped
      end

      def invalid_name_result
        { success: false, response: { error: { message: "Invalid eval name: #{eval_name}" } } }
      end

      def resolve_skill
        Services::SkillResolver.call(skill_name)
      rescue ArgumentError
        nil
      end

      def skill_not_found_result
        { success: false, response: { error: { message: "Skill not found: #{skill_name}" } } }
      end

      def read_skill_content(skill_path)
        skill_md = File.join(skill_path, 'SKILL.md')
        File.exist?(skill_md) ? File.read(skill_md) : ''
      end

      def generate_eval(skill_content)
        prompt = GENERATION_PROMPT + "\n\n#{skill_content}"

        provider = load_provider
        return mock_generate if provider.nil? || provider.name == 'mock'

        client_class = SkillBench::Clients::ProviderRegistry.for(provider.runtime.to_sym)
        response = client_class.call(
          system_prompt: '',
          messages: [{ role: 'user', content: prompt }],
          model: provider.llm,
          **provider.merged_config
        )

        return { success: false, response: { error: { message: 'LLM generation failed' } } } unless response[:success]

        parse_generated_json(response[:result])
      end

      def load_provider
        config = SkillBench::Models::Config.load
        config.to_provider
      rescue Errno::ENOENT
        nil
      end

      def mock_generate
        parse_generated_json(<<~JSON)
          {
            "task": "Apply the skill patterns to solve a representative task.",
            "context": "Evaluate skill application",
            "dimensions": [
              { "name": "correctness", "max_score": 30 },
              { "name": "skill_adherence", "max_score": 25 },
              { "name": "code_quality", "max_score": 20 },
              { "name": "test_coverage", "max_score": 15 },
              { "name": "documentation", "max_score": 10 }
            ],
            "pass_threshold": 70,
            "minimum_delta": 10
          }
        JSON
      end

      def parse_generated_json(json_text)
        data = JSON.parse(json_text)
        { success: true, response: { data: data } }
      rescue JSON::ParserError => e
        { success: false, response: { error: { message: "Failed to parse generated eval: #{e.message}" } } }
      end

      def write_eval_files(sanitized_name, data)
        eval_dir = File.join('evals', sanitized_name)
        FileUtils.mkdir_p(eval_dir)

        File.write(File.join(eval_dir, 'task.md'), data['task'] || data[:task] || '')
        File.write(File.join(eval_dir, 'criteria.json'), JSON.pretty_generate(build_criteria_hash(data)))
      end

      def build_criteria_hash(data)
        {
          context: data.fetch('context', data[:context] || ''),
          dimensions: data.fetch('dimensions', data[:dimensions] || []),
          pass_threshold: extract_numeric(data, 'pass_threshold', 70),
          minimum_delta: extract_numeric(data, 'minimum_delta', 10)
        }
      end

      def extract_numeric(data, key, default)
        return data[key] if data.key?(key)

        sym = key.to_sym
        return data[sym] if data.key?(sym)

        default
      end
    end
  end
end
