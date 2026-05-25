# frozen_string_literal: true

require 'optparse'

module SkillBench
  module Cli
    # Handles the `skill-bench run` subcommand.
    # Parses options and delegates to Commands::Run.
    class RunCommand
      #
      # @param argv [Array<String>] Raw CLI arguments
      # @return [Integer] Exit code
      def self.call(argv)
        new(argv).call
      end

      # @param argv [Array<String>] Raw CLI arguments
      def initialize(argv)
        @argv = argv
      end

      # Parses options and runs the eval.
      #
      # @return [Integer] Exit code
      def call
        options = { skill_names: [] }
        parser = build_parser(options)
        parser.parse!(@argv)

        eval_name = @argv.shift
        return error_missing_eval unless eval_name
        return error_missing_skill if options[:skill_names].empty? && !options[:pack]

        options[:eval_name] = eval_name
        exec_options = options.reject { |key| key == :format }
        result = Commands::Run.run(**exec_options)
        ResultPrinter.call(result, format: options[:format] || :human)
      rescue HelpRequested
        0
      rescue StandardError => e
        warn "Error: #{e.message}"
        1
      end

      private

      def build_parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: skill-bench run <eval> [options]'
          opts.on('--skill NAME', 'Skill to use (can be specified multiple times)') { |v| options[:skill_names] << v }
          opts.on('--pack NAME', 'Pack context for skill resolution') { |v| options[:pack] = v }
          opts.on('--registry-manifest PATH', 'Path to registry.json manifest') { |v| options[:registry_manifest] = v }
          opts.on('--format FORMAT', 'Output format (human, json, junit)') { |v| options[:format] = v.to_sym }
          opts.on('-h', '--help', 'Prints this help') do
            puts opts
            raise SkillBench::HelpRequested
          end
        end
      end

      def error_missing_eval
        warn 'Error: eval name is required'
        warn 'Usage: skill-bench run <eval> [--skill <name>] [--pack <name>]'
        1
      end

      def error_missing_skill
        warn 'Error: skill name or pack is required'
        warn 'Usage: skill-bench run <eval> --skill <name> [--pack <name>]'
        1
      end
    end
  end
end
