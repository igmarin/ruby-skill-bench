# frozen_string_literal: true

require 'optparse'
require_relative 'commands/init'
require_relative 'commands/run'
require_relative 'commands/skill_new'
require_relative 'commands/eval_new'

module SkillBench
  # CLI dispatcher that routes subcommands to their handlers.
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
    def call
      return print_help if @argv.empty?

      subcommand = @argv.shift
      case subcommand
      when 'init'
        handle_init(@argv)
      when 'run'
        handle_run(@argv)
      when 'skill'
        handle_skill(@argv)
      when 'eval'
        handle_eval(@argv)
      when '-h', '--help', 'help'
        print_help
      else
        warn "Unknown subcommand: #{subcommand}"
        warn "Run 'skill-bench help' for usage."
        1
      end
    end

    private

    def handle_init(argv)
      options = { force: false }
      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: skill-bench init [options]'
        opts.on('--force', 'Overwrite existing config file') { options[:force] = true }
        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end
      parser.parse!(argv)

      Commands::Init.run(**options)
      puts "Created #{SkillBench::Config::CONFIG_FILENAME}"
      0
    rescue StandardError => e
      warn "Error: #{e.message}"
      1
    end

    def handle_run(argv)
      options = {}
      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: skill-bench run <eval> [options]'
        opts.on('--skill NAME', 'Skill to use') { |v| options[:skill_name] = v }
        opts.on('--provider NAME', 'Provider to use') { |v| options[:provider_name] = v }
        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end
      parser.parse!(argv)

      eval_name = argv.shift
      unless eval_name
        warn 'Error: eval name is required'
        warn 'Usage: skill-bench run <eval> --skill <name> --provider <name>'
        return 1
      end

      options[:eval_name] = eval_name
      result = Commands::Run.run(**options)
      print_result(result)
    rescue StandardError => e
      warn "Error: #{e.message}"
      1
    end

    def handle_skill(argv)
      action = argv.shift
      case action
      when 'new'
        handle_skill_new(argv)
      when '-h', '--help', 'help', nil
        puts 'Usage: skill-bench skill new <name> [options]'
        puts '  --mode MODE        simple, advanced, or rails (default: simple)'
        puts '  --template TYPE    service_object, concern, active_record_model (default: service_object)'
        0
      else
        warn "Unknown skill action: #{action}"
        1
      end
    end

    def handle_skill_new(argv)
      options = { mode: 'simple', template: 'service_object' }
      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: skill-bench skill new <name> [options]'
        opts.on('--mode MODE', 'simple, advanced, or rails') { |v| options[:mode] = v }
        opts.on('--template TYPE', 'service_object, concern, active_record_model') { |v| options[:template] = v }
        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end
      parser.parse!(argv)

      name = argv.shift
      unless name
        warn 'Error: skill name is required'
        return 1
      end

      Commands::SkillNew.run(name: name, **options)
      puts "Created skill: #{name}"
      0
    rescue StandardError => e
      warn "Error: #{e.message}"
      1
    end

    def handle_eval(argv)
      action = argv.shift
      case action
      when 'new'
        handle_eval_new(argv)
      when '-h', '--help', 'help', nil
        puts 'Usage: skill-bench eval new <name> [options]'
        puts '  --runtime TYPE  rails, ruby, etc. (default: ruby)'
        0
      else
        warn "Unknown eval action: #{action}"
        1
      end
    end

    def handle_eval_new(argv)
      options = { runtime: 'ruby' }
      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: skill-bench eval new <name> [options]'
        opts.on('--runtime TYPE', 'rails, ruby, etc.') { |v| options[:runtime] = v }
        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end
      parser.parse!(argv)

      name = argv.shift
      unless name
        warn 'Error: eval name is required'
        return 1
      end

      Commands::EvalNew.run(name: name, **options)
      puts "Created eval: #{name}"
      0
    rescue StandardError => e
      warn "Error: #{e.message}"
      1
    end

    def print_result(result)
      if result[:success]
        puts "Result: #{result[:response][:message]}"
        0
      else
        warn "Error: #{result.dig(:response, :error, :message)}"
        1
      end
    end

    def print_help
      puts <<~USAGE
        Usage: skill-bench <subcommand> [options]

        Subcommands:
          init              Generate configuration file
          run <eval>        Run an evaluation
          skill new <name>  Create a new skill
          eval new <name>   Create a new eval

        Options:
          -h, --help        Show this help message
      USAGE
      0
    end
  end
end
