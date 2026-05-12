# frozen_string_literal: true

require 'pathname'
require_relative 'runner'
require_relative 'services/option_parser_service'
require_relative 'services/result_printer_service'
require_relative 'services/output_persistence_service'

module SkillBench
  # Implements the `skill-bench run` CLI command.
  # Orchestrates option parsing, evaluation execution, result printing, and output persistence.
  # @deprecated Use {SkillBench::Cli::RunCommand} and {SkillBench::Services::RunnerService} instead.
  class EvaluateCommand
    # Parses arguments, runs the evaluator, prints the report, and records history.
    #
    # @param argv [Array<String>] Raw CLI arguments.
    # @param stdout [#puts, #write] Output stream for user-visible messages.
    # @return [Integer] Shell-compatible exit code.
    # @raise [OptionParser::ParseError] when invalid CLI flags are provided.
    # @raise [SystemCallError] if writing output fails.
    def self.call(argv, stdout: $stdout)
      new(argv, stdout: stdout).call
    end

    # @param argv [Array<String>] Raw CLI arguments.
    # @param stdout [#puts, #write] Output stream for user-visible messages.
    def initialize(argv, stdout:)
      @argv = argv
      @stdout = stdout
      @options = nil
    end

    # Executes the command by orchestrating service objects.
    #
    # @return [Integer] Shell-compatible exit code.
    # @raise [OptionParser::ParseError] when invalid CLI flags are provided.
    # @raise [SystemCallError] when the optional JSON output file cannot be written.
    def call
      return 1 unless parse_options? && validate_options?

      result = run_evaluation
      return 1 unless result[:success]

      return 1 unless persist_output?(result)

      SkillBench::HistoryRecorder.record(
        result,
        source_path: result[:source_path],
        model: SkillBench::Config.model
      )

      0
    end

    private

    def parse_options?
      options_result = Services::OptionParserService.call(@argv)
      @options = options_result[:response]

      unless options_result[:success]
        @stdout.puts "Error: #{@options[:error][:message]}"
        return false
      end

      true
    end

    def validate_options?
      eval_path = @options[:eval]
      return true if eval_path

      @stdout.puts 'Error: The --eval option is required.'
      @stdout.puts 'Example: bin/evaluate -e evals/skills/infrastructure/rails-api-versioning/api-versioning-with-controller-inheritan'
      false
    end

    def run_evaluation
      skill_option = @options[:skill]
      eval_path = safe_expand_path(@options[:eval])
      skill_path = skill_option ? safe_expand_path(skill_option) : nil

      result = SkillBench::Runner.call(
        eval_folder_path: eval_path,
        skill_path: skill_path
      )
      Services::ResultPrinterService.call(result, stdout: @stdout)
      result
    end

    def persist_output?(result)
      output_result = Services::OutputPersistenceService.call(result, output_path: @options[:output])
      output_response = output_result[:response]
      message = output_response[:message]

      if output_result[:success]
        @stdout.puts(message) if message
        true
      else
        @stdout.puts "Error saving report: #{output_response[:error][:message]}"
        false
      end
    end

    def safe_expand_path(path)
      expanded = File.expand_path(path)
      base = File.expand_path(Dir.pwd)

      real_expanded = File.exist?(expanded) ? File.realpath(expanded) : expanded
      real_base = File.realpath(base)

      relative = Pathname.new(real_expanded).relative_path_from(Pathname.new(real_base)).to_s
      raise ArgumentError, "Path '#{path}' resolves outside the current working directory" if relative.start_with?('..')

      expanded
    rescue Errno::ENOENT, Errno::EACCES => e
      raise ArgumentError, "Path '#{path}' is not accessible: #{e.message}"
    end
  end
end
