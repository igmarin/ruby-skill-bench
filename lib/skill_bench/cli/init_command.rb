# frozen_string_literal: true

require 'optparse'

module SkillBench
  module Cli
    # Handles the `skill-bench init` subcommand.
    # Parses options and delegates to Commands::Init.
    class InitCommand
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

      # Parses options and runs init.
      #
      # @return [Integer] Exit code
      def call
        options = { force: false, provider: nil }
        parser = build_parser(options)
        parser.parse!(@argv)

        return error_missing_provider unless options[:provider]

        Commands::Init.run(**options)
        puts "Created #{SkillBench::Config::CONFIG_FILENAME}"
        0
      rescue SkillBench::HelpRequested
        0
      rescue StandardError => e
        warn "Error: #{e.message}"
        1
      end

      private

      def build_parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: skill-bench init --<provider> [options]'
          register_provider_options(opts, options)
          opts.on('--force', 'Overwrite existing config file') { options[:force] = true }
          opts.on('-h', '--help', 'Prints this help') do
            puts opts
            raise SkillBench::HelpRequested
          end
        end
      end

      def register_provider_options(parser, options)
        SkillBench::ProviderSchemas.names.each do |name|
          parser.on("--#{name}", "Generate config for #{name.to_s.capitalize}") { options[:provider] = name }
        end
      end

      def error_missing_provider
        providers = SkillBench::ProviderSchemas.names.map { |provider_name| "--#{provider_name}" }.join(', ')
        warn "Error: provider is required. Use one of: #{providers}"
        1
      end
    end
  end
end
