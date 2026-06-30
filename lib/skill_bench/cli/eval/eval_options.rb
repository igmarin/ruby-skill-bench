# frozen_string_literal: true

require 'optparse'

module SkillBench
  module Cli
    module Eval
      # Base class for eval command option parsing
      class BaseEvalOptions
        attr_reader :options, :parser

        # Initializes the option set and the OptionParser used to parse the command's arguments.
        def initialize
          @options = default_options
          @parser = create_parser
        end

        # Parses command line arguments
        #
        # @param argv [Array<String>] Command line arguments
        # @return [Array<String>] Remaining arguments after parsing options
        def parse!(argv)
          parser.parse!(argv)
        end

        protected

        # Override in subclasses to define default options
        def default_options
          {}
        end

        # Override in subclasses to configure OptionParser
        def create_parser
          OptionParser.new
        end
      end

      # Options parser for 'eval new' command
      class NewEvalOptions < BaseEvalOptions
        protected

        # @return [Hash] default options for the `eval new` command, with the runtime defaulting to "ruby"
        def default_options
          { runtime: 'ruby' }
        end

        # @return [OptionParser] parser for the `eval new` command, handling --runtime and --help
        def create_parser
          OptionParser.new do |opts|
            opts.banner = 'Usage: skill-bench eval new <name> [options]'
            opts.on('--runtime TYPE', 'rails, ruby, etc.') { |v| @options[:runtime] = v }
            opts.on('-h', '--help', 'Prints this help') do
              puts opts
              raise HelpRequested
            end
          end
        end
      end

      # Options parser for 'eval generate' command
      class GenerateEvalOptions < BaseEvalOptions
        protected

        # @return [OptionParser] parser for the `eval generate` command, handling --name and --help
        def create_parser
          OptionParser.new do |opts|
            opts.banner = 'Usage: skill-bench eval generate <skill-name> [options]'
            opts.on('--name NAME', 'Name for generated eval') { |v| @options[:eval_name] = v }
            opts.on('-h', '--help', 'Prints this help') do
              puts opts
              raise HelpRequested
            end
          end
        end
      end
    end
  end
end
