# frozen_string_literal: true

require 'pathname'
require 'parallel'
require_relative 'runner_service'
require_relative '../output_formatter'
require_relative '../runner'

module SkillBench
  module Services
    # Orchestrates running many evals in a single batch.
    #
    # Discovers every eval under a target directory and runs
    # {RunnerService} over each, returning an aggregate envelope with
    # per-eval results and a pass/fail summary.
    #
    # Discovery reuses {SkillBench::Runner.discover_task_dirs} but never
    # routes through the deprecated {SkillBench::Task::Evaluator}: each eval
    # is executed by the supported {RunnerService}.
    class BatchRunnerService
      # Default directory scanned for evals when none is supplied.
      DEFAULT_EVALS_DIR = 'evals'

      # Default batch-level thread count.
      #
      # Each {RunnerService.call} already runs its baseline and context
      # agents concurrently (#26), so this is kept modest to bound nested
      # thread usage (batch threads x per-eval threads).
      DEFAULT_THREADS = 2

      # Runs every eval discovered under +evals_dir+.
      #
      # @param skill_names [Array<String>] Names of the skills to apply to every eval
      # @param evals_dir [String] Directory to scan for evals
      # @param pack [String, nil] Optional pack name for registry-based skill resolution
      # @param registry_manifest [String, nil] Optional path to registry.json manifest
      # @param threads [Integer] Batch-level thread count
      # @return [Hash] Aggregate envelope with :results and :summary
      # @raise [ArgumentError] when no evals are found under +evals_dir+
      def self.call(skill_names:, evals_dir: DEFAULT_EVALS_DIR, pack: nil, registry_manifest: nil, threads: DEFAULT_THREADS)
        new(
          skill_names: skill_names,
          evals_dir: evals_dir,
          pack: pack,
          registry_manifest: registry_manifest,
          threads: threads
        ).call
      end

      # @param skill_names [Array<String>] Names of the skills
      # @param evals_dir [String] Directory to scan for evals
      # @param pack [String, nil] Optional pack name
      # @param registry_manifest [String, nil] Optional registry.json path
      # @param threads [Integer] Batch-level thread count
      def initialize(skill_names:, evals_dir:, pack:, registry_manifest:, threads:)
        @skill_names = skill_names
        @evals_dir = evals_dir
        @pack = pack
        @registry_manifest = registry_manifest
        @threads = threads
      end

      # Discovers the target evals and runs each through {RunnerService}.
      #
      # @return [Hash] Aggregate envelope with :results and :summary
      # @raise [ArgumentError] when no evals are found under the directory
      def call
        eval_dirs = discover_eval_dirs
        raise ArgumentError, "No evals found under #{evals_dir}" if eval_dirs.empty?

        results = run_all(eval_dirs)
        { results: results, summary: summarize(results) }
      end

      private

      attr_reader :skill_names, :evals_dir, :pack, :registry_manifest, :threads

      # Finds every eval directory under the configured root.
      #
      # @return [Array<Pathname>] Directories that contain a task.md
      def discover_eval_dirs
        SkillBench::Runner.discover_task_dirs(Pathname.new(evals_dir))
      end

      # Runs every eval directory through {RunnerService} concurrently.
      #
      # @param eval_dirs [Array<Pathname>] Discovered eval directories
      # @return [Array<Hash>] Per-eval RunnerService results
      def run_all(eval_dirs)
        Parallel.map(eval_dirs, in_threads: threads) do |eval_dir|
          RunnerService.call(
            eval_name: eval_dir.to_s,
            skill_names: skill_names,
            pack: pack,
            registry_manifest: registry_manifest
          )
        end
      end

      # Tallies pass/fail counts, reusing the single-eval exit-code logic.
      #
      # @param results [Array<Hash>] Per-eval results
      # @return [Hash] Summary with :total, :passed and :failed counts
      def summarize(results)
        passed = results.count { |result| SkillBench::OutputFormatter.exit_code(result).zero? }
        { total: results.size, passed: passed, failed: results.size - passed }
      end
    end
  end
end
