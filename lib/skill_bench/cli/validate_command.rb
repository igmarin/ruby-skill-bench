# frozen_string_literal: true

require 'json'
require 'optparse'

module SkillBench
  module Cli
    # Handles the `skill-bench validate` / `doctor` subcommand.
    #
    # Runs read-only pre-flight checks and prints a PASS/FAIL report:
    #   1. Criteria JSON structure (via {Models::CriteriaValidator}).
    #   2. skill-bench.json shape (hand-rolled, lightweight schema check).
    #   3. Provider credentials for the configured non-mock provider.
    #
    # It never runs an eval and never makes a network call.
    class ValidateCommand
      # Default criteria file validated when --criteria is not given.
      DEFAULT_CRITERIA = 'criteria.json'

      # @param argv [Array<String>] Raw CLI arguments
      # @return [Integer] Exit code
      def self.call(argv)
        new(argv).call
      end

      # @param argv [Array<String>] Raw CLI arguments
      def initialize(argv)
        @argv = argv
      end

      # Parses options, runs the pre-flight checks, and prints the report.
      #
      # @return [Integer] Exit code (0 when all checks pass, 1 otherwise)
      def call
        options = parse_options
        config_path = options[:config] || SkillBench::Config::CONFIG_FILENAME
        config_data = load_config_data(config_path)
        results = [
          check_criteria(options),
          check_config(config_path, config_data),
          check_provider_key(config_data)
        ]
        print_report(results)
        results.any? { |result| result[:status] == :fail } ? 1 : 0
      rescue HelpRequested
        0
      rescue StandardError => e
        warn "Error: #{e.message}"
        1
      end

      private

      def parse_options
        options = {}
        build_parser(options).parse!(@argv)
        options
      end

      def build_parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: skill-bench validate [options]'
          opts.on('--criteria PATH', 'Criteria JSON file to validate (default: criteria.json)') { |v| options[:criteria] = v }
          opts.on('--config PATH', 'Config file to validate (default: skill-bench.json)') { |v| options[:config] = v }
          opts.on('-h', '--help', 'Prints this help') do
            puts opts
            raise SkillBench::HelpRequested
          end
        end
      end

      # --- Check (a): criteria ------------------------------------------------

      def check_criteria(options)
        path = options[:criteria] || DEFAULT_CRITERIA
        unless File.exist?(path)
          return fail_result('criteria', "criteria file not found: #{path}") if options[:criteria]

          return skip_result('criteria', "no #{DEFAULT_CRITERIA} found (skipped)")
        end

        result = Models::CriteriaValidator.call(path:)
        return pass_result('criteria', "#{path} is valid") if result[:success]

        fail_result('criteria', "#{path}: #{criteria_error(result)}")
      end

      def criteria_error(result)
        result.dig(:response, :error, :message) || 'invalid criteria'
      end

      # --- Check (b): config shape -------------------------------------------

      def check_config(path, config_data)
        case config_data[:status]
        when :missing
          fail_result('config', "#{path} not found")
        when :invalid_json
          fail_result('config', "#{path} is not valid JSON: #{config_data[:message]}")
        else
          validate_config_shape(path, config_data[:data])
        end
      end

      def validate_config_shape(path, data)
        return fail_result('config', "#{path} must contain a JSON object") unless data.is_a?(Hash)

        errors = config_shape_errors(data)
        return fail_result('config', errors.join('; ')) if errors.any?

        pass_result('config', "#{path} matches the expected shape")
      end

      def config_shape_errors(data)
        errors = provider_errors(data[:provider])
        errors.concat(max_execution_time_errors(data[:max_execution_time]))
        errors << "'config' must be an object" if data.key?(:config) && !data[:config].is_a?(Hash)
        errors
      end

      def provider_errors(provider)
        return ["'provider' is required"] if provider.nil?
        return ["'provider' must be a string"] unless provider.is_a?(String)

        allowed = Models::Provider::ALLOWED_PROVIDERS
        return [] if allowed.include?(provider)

        ["'provider' '#{provider}' is not one of: #{allowed.join(', ')}"]
      end

      def max_execution_time_errors(value)
        return [] if value.nil?
        return [] if value.is_a?(Integer) && value.positive?

        ["'max_execution_time' must be a positive integer"]
      end

      # --- Check (c): provider key -------------------------------------------

      def check_provider_key(config_data)
        return skip_result('provider key', 'skipped (no usable config)') unless config_data[:status] == :ok

        provider = config_provider(config_data[:data])
        return skip_result('provider key', 'skipped (provider invalid)') unless provider
        return pass_result('provider key', 'mock provider requires no API key') if provider == 'mock'

        missing = missing_provider_keys(provider, config_data[:data][:config])
        return pass_result('provider key', "#{provider} credentials present") if missing.empty?

        fail_result('provider key', "#{provider} is missing: #{missing.join(', ')}")
      rescue StandardError => e
        # Building the client can raise on unrelated config (e.g. base_url
        # validation); surface that as a structured FAIL rather than crashing.
        fail_result('provider key', "#{provider} config is invalid: #{e.message}")
      end

      def config_provider(data)
        return nil unless data.is_a?(Hash)

        provider = data[:provider]
        return nil unless provider.is_a?(String) && Models::Provider::ALLOWED_PROVIDERS.include?(provider)

        provider
      end

      def missing_provider_keys(provider, provider_config)
        provider_sym = provider.to_sym
        options = provider_client_options(provider_sym, provider_config)
        client = Clients::ProviderRegistry.for(provider_sym).new(options)
        return [] unless client.respond_to?(:missing_config_keys, true)

        client.send(:missing_config_keys)
      end

      def provider_client_options(provider_sym, provider_config)
        options = provider_config.is_a?(Hash) ? provider_config.dup : {}
        Models::Provider::ENV_OVERRIDABLE_SETTINGS.each do |setting|
          value = env_setting(provider_sym, setting)
          options[setting] = value unless value.nil?
        end
        options
      end

      def env_setting(provider_sym, setting)
        provider = provider_sym.to_s.upcase
        name = setting.to_s.upcase
        ["SKILL_BENCH_#{provider}_#{name}", "#{provider}_#{name}"].each do |var|
          value = ENV.fetch(var, nil)
          return value if value && !value.empty?
        end
        nil
      end

      # --- Config loading ----------------------------------------------------

      def load_config_data(path)
        return { status: :missing } unless File.exist?(path)

        { status: :ok, data: JSON.parse(File.read(path), symbolize_names: true) }
      rescue JSON::ParserError => e
        { status: :invalid_json, message: e.message }
      end

      # --- Reporting ---------------------------------------------------------

      def print_report(results)
        puts 'skill-bench validate'
        puts
        results.each { |result| puts format_result(result) }
        puts
        puts summary_line(results)
      end

      def format_result(result)
        "[#{label(result[:status])}] #{result[:name].ljust(13)} #{result[:message]}"
      end

      def label(status)
        { pass: 'PASS', fail: 'FAIL', skip: 'SKIP' }.fetch(status)
      end

      def summary_line(results)
        failed = results.count { |result| result[:status] == :fail }
        return "#{failed} check(s) failed." if failed.positive?

        'All checks passed.'
      end

      def pass_result(name, message)
        { name:, status: :pass, message: }
      end

      def fail_result(name, message)
        { name:, status: :fail, message: }
      end

      def skip_result(name, message)
        { name:, status: :skip, message: }
      end
    end
  end
end
