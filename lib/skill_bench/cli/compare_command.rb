# frozen_string_literal: true

require 'optparse'

module SkillBench
  module Cli
    # Handles the `skill-bench compare` command.
    # Runs the same eval with two skill variants and reports the comparison.
    class CompareCommand
      # Parses argv and executes the comparison.
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

      # Parses options, runs both variants, and prints a comparison report.
      #
      # @return [Integer] Exit code (0 if both pass, 1 otherwise)
      def call
        options = { format: :human }
        parser = build_parser(options)
        parser.parse!(@argv)

        skill_name = @argv.shift
        return error_missing_skill unless skill_name
        return error_missing_variant_a unless options[:variant_a]
        return error_missing_variant_b unless options[:variant_b]
        return error_missing_eval unless options[:eval]

        variant_a = parse_variant(options[:variant_a])
        variant_b = parse_variant(options[:variant_b])

        puts "--- Running Variant A: #{options[:variant_a]} ---"
        result_a = run_variant(variant_a, skill_name, options[:eval], options[:format])

        puts "\n--- Running Variant B: #{options[:variant_b]} ---"
        result_b = run_variant(variant_b, skill_name, options[:eval], options[:format])

        print_comparison(result_a, result_b, options[:variant_a], options[:variant_b])

        exit_code_for(result_a, result_b)
      rescue HelpRequested
        0
      rescue StandardError => e
        warn "Error: #{e.message}"
        1
      end

      private

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

      def parse_variant(spec)
        if spec.start_with?('pack:')
          { type: :pack, name: spec.sub('pack:', '') }
        else
          { type: :path, path: spec }
        end
      end

      def run_variant(variant, skill_name, eval_path, _format)
        skill_paths = case variant[:type]
                      when :pack
                        pack_name = variant[:name]
                        manifest_path = find_manifest
                        resolver = Registry::PackResolver.new(manifest_path)
                        resolved = resolver.resolve_skill(pack_name, skill_name)
                        raise ArgumentError, "Skill '#{skill_name}' not found in pack '#{pack_name}'" unless resolved

                        [resolved]
                      when :path
                        [variant[:path]]
                      end

        Services::RunnerService.call(
          eval_name: eval_path,
          skill_names: skill_paths
        )
      end

      def find_manifest
        manifest_path = File.expand_path('../agent-mcp-runtime/registry.json', Dir.pwd)
        raise ArgumentError, "Registry manifest not found: #{manifest_path}" unless File.exist?(manifest_path)

        manifest_path
      end

      def print_comparison(result_a, result_b, label_a, label_b)
        puts "\n=== Comparison Report ==="
        puts "| Dimension | #{label_a} | #{label_b} | Delta |"
        puts '|-----------|----------|----------|-------|'

        report_a = result_a.dig(:response, :report)
        report_b = result_b.dig(:response, :report)
        return unless report_a && report_b

        report_a.dimensions.each_with_index do |dim, i|
          score_a = dim.score
          score_b = report_b.dimensions[i]&.score || 0
          delta = score_a - score_b
          puts format('| %<name>-9s | %<a>8.1f | %<b>8.1f | %<delta>+5.1f |',
                      name: dim.name, a: score_a, b: score_b, delta: delta.to_f)
        end

        total_a = result_a.dig(:response, :report, :total)
        total_b = result_b.dig(:response, :report, :total)
        if total_a && total_b
          delta = total_a - total_b
          puts format('| %<name>-9s | %<a>8.1f | %<b>8.1f | %<delta>+5.1f |',
                      name: 'TOTAL', a: total_a.to_f, b: total_b.to_f, delta: delta.to_f)
        end

        verdict_a = result_a.dig(:response, :report, :verdict)
        verdict_b = result_b.dig(:response, :report, :verdict)
        puts "| A: #{verdict_a} | B: #{verdict_b} |"
      end

      def exit_code_for(result_a, result_b)
        passed_a = result_a.dig(:response, :report, :verdict) == 'PASS'
        passed_b = result_b.dig(:response, :report, :verdict) == 'PASS'
        passed_a && passed_b ? 0 : 1
      end

      def error_missing_skill
        warn 'Error: skill name is required'
        warn 'Usage: skill-bench compare <skill-name> --variant-a <spec> --variant-b <spec> --eval <path>'
        1
      end

      def error_missing_variant_a
        warn 'Error: --variant-a is required'
        1
      end

      def error_missing_variant_b
        warn 'Error: --variant-b is required'
        1
      end

      def error_missing_eval
        warn 'Error: --eval is required'
        1
      end
    end
  end
end
