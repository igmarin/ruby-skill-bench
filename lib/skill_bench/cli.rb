# frozen_string_literal: true

require_relative 'cli/init_command'
require_relative 'cli/run_command'
require_relative 'cli/skill_command'
require_relative 'cli/eval_command'
require_relative 'cli/help_printer'
require_relative 'cli/result_printer'

module SkillBench
  # Raised when -h/--help is passed to abort OptionParser and return exit code 0.
  class HelpRequested < StandardError; end

  # Thin CLI dispatcher that routes subcommands to their handlers.
  class CLI
    # Entry point called from bin/skill-bench.
    #
    # @param argv [Array<String>] Raw CLI arguments.
    # @return [Integer] Exit code.
    def self.call(argv)
      new(argv).call
    end

    # @param argv [Array<String>] Raw CLI arguments.
    def initialize(argv)
      @argv = argv
    end

    # Dispatches to the appropriate subcommand handler.
    #
    # @return [Integer] Exit code.
    # :reek:DuplicateMethodCall { enabled: false }
    def call
      help = -> { Cli::HelpPrinter.call }
      return help.call if @argv.empty?

      subcommand = @argv.shift
      case subcommand
      when 'init'  then Cli::InitCommand.call(@argv)
      when 'run'   then Cli::RunCommand.call(@argv)
      when 'skill' then Cli::SkillCommand.call(@argv)
      when 'eval'  then Cli::EvalCommand.call(@argv)
      when '-h', '--help', 'help'
        help.call
      else
        warn "Unknown subcommand: #{subcommand}"
        warn "Run 'skill-bench help' for usage."
        1
      end
    end
  end
end
