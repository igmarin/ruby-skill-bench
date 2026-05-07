# frozen_string_literal: true

require 'fileutils'
require_relative '../rails/skill_templates'

module AgentEval
  module Commands
    # Handles the `agent-eval skill new` command
    class SkillNew
      # Run the skill new command
      # @param name [String] Skill name
      # @param mode [String] "simple", "advanced", or "rails"
      # @param template [String] Rails template type (service_object, concern, active_record_model)
      # @return [void]
      # @raise [ArgumentError] if mode is invalid
      def self.run(name:, mode: 'simple', template: 'service_object')
        skill_path = File.join('skills', name)
        FileUtils.mkdir_p(skill_path)

        case mode
        when 'simple'
          create_simple_skill(skill_path, name)
        when 'advanced'
          create_advanced_skill(skill_path, name)
        when 'rails'
          create_rails_skill(skill_path, name, template)
        else
          raise ArgumentError, "Invalid mode: #{mode}. Use 'simple', 'advanced', or 'rails'."
        end
      end

      # Create a simple skill with SKILL.md
      # @param path [String] Skill directory path
      # @param name [String] Skill name
      # @return [void]
      def self.create_simple_skill(path, name)
        File.write(File.join(path, 'SKILL.md'), simple_skill_template(name))
      end

      # Create an advanced skill with Ruby class
      # @param path [String] Skill directory path
      # @param name [String] Skill name
      # @return [void]
      def self.create_advanced_skill(path, name)
        File.write(File.join(path, 'skill.rb'), advanced_skill_template(name))
      end

      # Generate simple skill template
      # @param name [String] Skill name
      # @return [String] Markdown template
      def self.simple_skill_template(name)
        <<~MARKDOWN
          # Skill: #{name}

          ## Description
          Add skill description here.

          ## Context
          Add context injection content here.

          ## Workflow
          Add workflow steps here.
        MARKDOWN
      end

      # Convert snake_case to CamelCase
      # @param string [String] String to convert
      # @return [String] CamelCase string
      def self.camelize(string)
        string.split(/[_\s]+/).map(&:capitalize).join
      end

      # Generate advanced skill template
      # @param name [String] Skill name
      # @return [String] Ruby class template
      def self.advanced_skill_template(name)
        class_name = camelize(name)
        <<~RUBY
          # frozen_string_literal: true

          module AgentEval
            module Skills
              class #{class_name}
                def initialize; end

                def call
                  # Implement skill logic here
                end
              end
            end
          end
        RUBY
      end

      # Create a Rails skill using templates
      # @param path [String] Skill directory path
      # @param name [String] Skill name
      # @param template [String] Template type (service_object, concern, active_record_model)
      # @return [void]
      def self.create_rails_skill(path, name, template)
        template_method = template.to_sym
        file_name = "#{template.sub('_object', '').sub('active_record_', '')}.rb"
        content = Rails::SkillTemplates.send(template_method, name)
        File.write(File.join(path, file_name), content)
      end
    end
  end
end
