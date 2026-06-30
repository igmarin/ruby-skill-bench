# frozen_string_literal: true

module SkillBench
  module Cli
    # Prints the CLI help/usage message.
    class HelpPrinter
      # Prints the help message and returns exit code 0.
      #
      # @return [Integer] Exit code (always 0)
      def self.call
        providers = SkillBench::Clients::ProviderSchemas.names.map { |name| "--#{name}" }.join(', ')

        puts <<~USAGE
          Usage: skill-bench <subcommand> [options]

          Subcommands:
            init --<provider> [--force]
              Generate configuration file
              Providers: #{providers}
              --force    Overwrite existing config file

            run <eval> --skill <name> [--skill <name>] [--format FORMAT] [--pack NAME]
              Run an evaluation (single eval, or a whole directory with --all)
              --skill    Skill to use (can be specified multiple times)
              --pack     Pack context for registry-based skill resolution
              --registry-manifest PATH  Path to registry.json manifest
              --format   Output format: human, json, junit, html (default: human)
              --all      Run every eval under evals/ (batch mode)
              --evals-dir DIR  Run every eval under DIR (batch mode)
              --summary  Emit a JSON summary gate for a batch run (batch mode)

            compare <skill-name> --variant-a SPEC --variant-b SPEC --eval PATH
              Compare the same skill across two pack variants
              --variant-a  First variant (e.g., "pack:rails" or "/path/to/skill")
              --variant-b  Second variant (e.g., "pack:hanami")
              --eval       Path to the eval directory

            skill new <name> [--mode MODE] [--template TYPE]
              Create a new skill
              --mode     simple, advanced, or rails (default: simple)
              --template service_object, concern, active_record_model (default: service_object)

            eval new <name> [--runtime TYPE]
              Create a new eval
              --runtime  rails, ruby, etc. (default: ruby)

            eval generate <skill-name> [--name <eval-name>]
              Auto-generate an eval from a skill
              --name     Name for the generated eval (optional)

            validate (alias: doctor) [--criteria PATH] [--config PATH]
              Run read-only pre-flight checks (no eval, no network)
              --criteria  Criteria JSON to validate (default: criteria.json)
              --config    Config file to validate (default: skill-bench.json)

          Global Options:
            -h, --help        Show this help message
        USAGE
        0
      end
    end
  end
end
