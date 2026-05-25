# frozen_string_literal: true

require 'optparse'

module SkillBench
  module Services
    # Parses CLI options for the compare command.
    class CompareOptionParser
      # Parses the given argv and returns the options hash.
      #
      # @param argv [Array<String>] Raw CLI arguments
      # @return [Hash] Parsed options with keys: :variant_a, :variant_b, :eval, :format
      # @raise [OptionParser::ParseError] when option parsing fails
      def self.call(argv)
        new(argv).call
      end

      # @param argv [Array<String>] Raw CLI arguments
      def initialize(argv)
        @argv = argv
      end

      # Parses options from argv.
      #
      # @return [Hash] Parsed options with keys: :variant_a, :variant_b, :eval, :format
      # @raise [OptionParser::ParseError] when option parsing fails
      def call
        options = { format: :human }
        parser = build_parser(options)
        parser.parse!(@argv)
        options
      end

      private

      # Builds the OptionParser instance.
      #
      # @param options [Hash] Options hash to populate
      # @return [OptionParser] Configured parser
      def build_parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: skill-bench compare <skill-name> [options]'
          opts.on('--variant-a SPEC', 'First variant (e.g., "pack:rails" or "/path/to/skill")') { |v| options[:variant_a] = v }
          opts.on('--variant-b SPEC', 'Second variant (e.g., "pack:hanami" or "/path/to/skill")') { |v| options[:variant_b] = v }
          opts.on('--eval PATH', 'Path to the eval directory') { |v| options[:eval] = v }
          opts.on('--format FORMAT', 'Output format (human, json)') { |v| options[:format] = v.to_sym }
          opts.on('-h', '--help', 'Prints this help') do
            puts opts
            raise SkillBench::HelpRequested
          end
        end
      end
    end
  end
end
