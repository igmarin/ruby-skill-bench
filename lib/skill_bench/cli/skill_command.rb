# frozen_string_literal: true

require 'optparse'

module SkillBench
  module Cli
    # Handles the `skill-bench skill` subcommand.
    # Parses options and delegates to Commands::SkillNew.
    class SkillCommand
      # Parses argv and executes the skill command.
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

      # Dispatches to the appropriate skill action.
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
          warn "Unknown skill action: #{action}"
          1
        end
      end

      private

      # :reek:NestedIterators { enabled: false }
      def handle_new(argv)
        options = { mode: 'simple', template: 'service_object' }
        parser = OptionParser.new do |opts|
          opts.banner = 'Usage: skill-bench skill new <name> [options]'
          opts.on('--mode MODE', 'simple, advanced, or rails') { |v| options[:mode] = v }
          opts.on('--template TYPE', 'service_object, concern, active_record_model') { |v| options[:template] = v }
          opts.on('-h', '--help', 'Prints this help') do
            puts opts
            raise SkillBench::HelpRequested
          end
        end
        parser.parse!(argv)

        name = argv.shift
        return error_missing_name unless name

        Commands::SkillNew.run(name: name, **options)
        puts "Created skill: #{name}"
        0
      rescue SkillBench::HelpRequested
        0
      rescue StandardError => e
        warn "Error: #{e.message}"
        1
      end

      def print_help
        puts 'Usage: skill-bench skill new <name> [options]'
        puts '  --mode MODE        simple, advanced, or rails (default: simple)'
        puts '  --template TYPE    service_object, concern, active_record_model (default: service_object)'
      end

      def error_missing_name
        warn 'Error: skill name is required'
        1
      end
    end
  end
end
