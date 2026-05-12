# frozen_string_literal: true

require 'fileutils'
require 'json'

module SkillBench
  module Commands
    # Handles the `skill-bench eval new` command
    class EvalNew
      # Allowed runtime values for eval scaffolding.
      ALLOWED_RUNTIMES = %w[ruby rails].freeze

      # Run the eval new command
      # @param name [String] Eval name
      # @param runtime [String] "ruby" or "rails" (default: ruby)
      # @return [void]
      # @raise [ArgumentError] if runtime is not in ALLOWED_RUNTIMES.
      def self.run(name:, runtime: 'ruby')
        raise ArgumentError, "Unsupported runtime '#{runtime}'. Allowed: #{ALLOWED_RUNTIMES.join(', ')}" unless ALLOWED_RUNTIMES.include?(runtime)

        eval_path = File.join('evals', name)
        FileUtils.mkdir_p(eval_path)

        create_task_md(eval_path, name)
        create_criteria_json(eval_path, runtime)
        create_rails_files(eval_path, name) if runtime == 'rails'
      end

      # Create task.md for the eval
      # @param path [String] Eval directory path
      # @param name [String] Eval name
      # @return [void]
      def self.create_task_md(path, name)
        File.write(File.join(path, 'task.md'), task_template(name))
      end

      # Create criteria.json for the eval
      # @param path [String] Eval directory path
      # @param runtime [String] Runtime type
      # @return [void]
      def self.create_criteria_json(path, runtime)
        criteria = default_criteria(runtime)
        File.write(File.join(path, 'criteria.json'), JSON.pretty_generate(criteria))
      end

      # Generate task.md template
      # @param name [String] Eval name
      # @return [String] Markdown template
      def self.task_template(name)
        <<~MARKDOWN
          # Eval: #{name}

          ## Task
          Describe the task for the agent here.

          ## Success Criteria
          Define what constitutes a successful completion.
        MARKDOWN
      end

      # Generate default criteria hash.
      #
      # @param runtime [String] Runtime type.
      # @return [Hash] Criteria configuration in the new format.
      def self.default_criteria(runtime)
        {
          context: "Evaluate #{runtime} task",
          dimensions: [
            { name: 'correctness', max_score: 30 },
            { name: 'skill_adherence', max_score: 25 },
            { name: 'code_quality', max_score: 20 },
            { name: 'test_coverage', max_score: 15 },
            { name: 'documentation', max_score: 10 }
          ],
          pass_threshold: 70,
          minimum_delta: 10
        }
      end

      # Create Rails-specific files for the eval
      # @param path [String] Eval directory path
      # @param _name [String] Eval name
      # @return [void]
      def self.create_rails_files(path, _name)
        File.write(File.join(path, 'rails_helper.rb'), "require 'rails_helper'\n")
      end
    end
  end
end
