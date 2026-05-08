# frozen_string_literal: true

require 'optparse'

module SkillBench
  module Cli
    # Handles the `skill-bench eval` subcommand.
    # Parses options and delegates to Commands::EvalNew.
    class EvalCommand
      # Parses argv and executes the eval command.
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

      # Dispatches to the appropriate eval action.
      #
      # :reek:NilCheck { enabled: false }
      def call
        action = @argv.shift
        case action
        when 'new'
          handle_new(@argv)
        when '-h', '--help', 'help', nil
          print_help
          0
        else
          warn "Unknown eval action: #{action}"
          1
        end
      end

      private

      # :reek:NestedIterators { enabled: false }
      def handle_new(argv)
        options = { runtime: 'ruby' }
        parser = OptionParser.new do |opts|
          opts.banner = 'Usage: skill-bench eval new <name> [options]'
          opts.on('--runtime TYPE', 'rails, ruby, etc.') { |v| options[:runtime] = v }
          opts.on('-h', '--help', 'Prints this help') do
            puts opts
            raise SkillBench::HelpRequested
          end
        end
        parser.parse!(argv)

        name = argv.shift
        return error_missing_name unless name

        Commands::EvalNew.run(name: name, **options)
        puts "Created eval: #{name}"
        0
      rescue SkillBench::HelpRequested
        0
      rescue StandardError => e
        warn "Error: #{e.message}"
        1
      end

      def print_help
        puts 'Usage: skill-bench eval new <name> [options]'
        puts '  --runtime TYPE  rails, ruby, etc. (default: ruby)'
      end

      def error_missing_name
        warn 'Error: eval name is required'
        1
      end
    end
  end
end
