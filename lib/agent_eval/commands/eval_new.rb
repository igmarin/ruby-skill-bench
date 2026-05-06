# frozen_string_literal: true

require 'fileutils'
require 'json'

module AgentEval
  module Commands
    # Handles the `agent-eval eval new` command
    class EvalNew
      # Run the eval new command
      # @param name [String] Eval name
      # @param runtime [String] "generic" or "rails"
      # @return [void]
      def self.run(name:, runtime: 'generic')
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

      # Generate default criteria hash
      # @param runtime [String] Runtime type
      # @return [Hash] Criteria configuration
      def self.default_criteria(runtime)
        {
          runtime: runtime,
          pass: { 'score_threshold' => 0.8 },
          fail: { 'score_threshold' => 0.5 }
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
