# frozen_string_literal: true

module SkillBench
  module Cli
    # Prints the CLI help/usage message.
    class HelpPrinter
      # Prints the help message and returns exit code 0.
      #
      # @return [Integer] Exit code (always 0)
      def self.call
        providers = SkillBench::ProviderSchemas.names.map { |name| "--#{name}" }.join(', ')

        puts <<~USAGE
          Usage: skill-bench <subcommand> [options]

          Subcommands:
            init --<provider> [--force]
              Generate configuration file
              Providers: #{providers}
              --force    Overwrite existing config file

            run <eval> --skill <name>
              Run an evaluation
              --skill    Skill to use (required)

            skill new <name> [--mode MODE] [--template TYPE]
              Create a new skill
              --mode     simple, advanced, or rails (default: simple)
              --template service_object, concern, active_record_model (default: service_object)

            eval new <name> [--runtime TYPE]
              Create a new eval
              --runtime  rails, ruby, etc. (default: ruby)

          Global Options:
            -h, --help        Show this help message
        USAGE
        0
      end
    end
  end
end
