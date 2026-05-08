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
        options = {}
        parser = build_parser(options)
        parser.parse!(@argv)

        eval_name = @argv.shift
        return error_missing_eval unless eval_name
        return error_missing_skill unless options[:skill_name]

        options[:eval_name] = eval_name
        result = Commands::Run.run(**options)
        ResultPrinter.call(result)
      rescue HelpRequested
        0
      rescue StandardError => e
        warn "Error: #{e.message}"
        1
      end

      private

      # :reek:FeatureEnvy { enabled: false }
      # :reek:NestedIterators { enabled: false }
      def build_parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: skill-bench run <eval> [options]'
          opts.on('--skill NAME', 'Skill to use') { |v| options[:skill_name] = v }
          opts.on('-h', '--help', 'Prints this help') do
            puts opts
            raise SkillBench::HelpRequested
          end
        end
      end

      def error_missing_eval
        warn 'Error: eval name is required'
        warn 'Usage: skill-bench run <eval> --skill <name>'
        1
      end

      def error_missing_skill
        warn 'Error: skill name is required'
        warn 'Usage: skill-bench run <eval> --skill <name>'
        1
      end
    end
  end
end
