# frozen_string_literal: true

require 'json'
require 'date'
require 'fileutils'

module SkillBench
  class HistoryRecorder
    # Service object for persisting evaluation results to benchmarks file.
    # Handles file I/O, path resolution, and directory creation.
    # Follows Single Responsibility Principle by isolating persistence concerns.
    class PersistenceService
      # The default file where historical benchmarks are stored.
      HISTORY_FILE = File.join(__dir__, '../..', 'benchmarks.json')

      # Records evaluation results into a historical benchmarks file.
      #
      # @param results [Hash] The results from a Runner.call.
      # @param source_path [String] The resolved source path used for the evaluation.
      # @param model [String] The model name used for the evaluation.
      # @return [Boolean] true if recorded successfully, false otherwise.
      # @raise [SystemCallError] when the history file cannot be written (handled internally).
      def self.record(results, source_path:, model:)
        return false unless results[:success]

        history_file = determine_history_file
        return false unless history_file

        history = load_history(history_file)
        entry = {
          timestamp: Time.now.iso8601,
          source_path: source_path,
          model: model,
          summary: SummaryService.summarize(results[:tasks])
        }

        history << entry

        atomic_write(history_file, history)
        logger = defined?(Rails) && Rails.respond_to?(:logger) ? Rails.logger : nil

        logger&.info("History recorded to #{history_file}")
        true
      rescue StandardError => e
        log_error(e)
        false
      end

      # Determines the best writable path for benchmarks.json.
      #
      # @return [String, nil] Path to writable file, or nil if none found.
      def self.determine_history_file
        env_path = resolve_env_history_file
        return env_path if env_path

        cwd_path = File.join(Dir.pwd, 'benchmarks.json')
        return cwd_path if writable?(cwd_path)

        home_dir = Dir.home
        local_path = File.join(home_dir, '.local', 'share', 'skill_bench', 'benchmarks.json')
        return local_path if prepare_and_writable?(local_path)

        xdg_data_home = ENV.fetch('XDG_DATA_HOME', File.join(home_dir, '.local', 'share'))
        xdg_path = File.join(xdg_data_home, 'skill_bench', 'benchmarks.json')
        return xdg_path if prepare_and_writable?(xdg_path)

        warn('Warning: Could not find writable location for benchmarks.json')
        nil
      end

      # Resolves the history file path from the SKILL_BENCH_HISTORY_FILE env var.
      #
      # @return [String, nil] Validated path if contained and writable, nil otherwise.
      def self.resolve_env_history_file
        env_history_file = ENV.fetch('SKILL_BENCH_HISTORY_FILE', nil).to_s.strip
        return nil if env_history_file.empty?

        env_path = File.expand_path(env_history_file)
        allowed_prefixes = allowed_history_prefixes.map { |prefix| File.expand_path(prefix) + File::SEPARATOR }
        env_path_with_sep = File.expand_path(env_path) + File::SEPARATOR
        is_contained = allowed_prefixes.any? { |prefix| env_path_with_sep.start_with?(prefix) || env_path == prefix.chomp(File::SEPARATOR) }
        return env_path if is_contained && prepare_and_writable?(env_path)

        warn "Warning: SKILL_BENCH_HISTORY_FILE '#{env_history_file}' rejected (outside allowed directories or not writable)."
        nil
      end
      private_class_method :resolve_env_history_file

      # Checks if a path is writable, creating parent dirs if needed.
      #
      # @param path [String] The path to check.
      # @return [Boolean]
      def self.prepare_and_writable?(path)
        dir_name = File.dirname(path)
        FileUtils.mkpath(dir_name)
        File.writable?(dir_name)
      rescue StandardError => e
        log_error(e)
        false
      end

      # Checks if a file location is writable.
      #
      # @param path [String] The path to check.
      # @return [Boolean]
      def self.writable?(path)
        File.writable?(File.dirname(path))
      rescue StandardError => e
        log_error(e)
        false
      end

      # Loads existing history from the benchmarks file.
      #
      # @param path [String] The path to the history file.
      # @return [Array<Hash>] The list of historical evaluation entries.
      def self.load_history(path = HISTORY_FILE)
        return [] unless File.exist?(path)

        JSON.parse(File.read(path), symbolize_names: true)
      rescue JSON::ParserError => e
        log_error(e, 'corrupted benchmarks.json')
        []
      rescue StandardError => e
        log_error(e)
        []
      end

      # Logs errors with backtrace.
      #
      # @param exception [StandardError]
      # @param context [String, nil] Optional context prefix for the log message.
      def self.log_error(exception, context = nil)
        prefix = context ? "#{context}: " : ''
        msg = "#{prefix}#{exception.message}\n#{exception.backtrace.first(5).join("\n")}"
        if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
          Rails.logger.error(msg)
        else
          warn("HistoryRecorder Error: #{msg}")
        end
      end

      # Returns allowed directory prefixes for history files.
      #
      # @return [Array<String>] allowed directory paths
      def self.allowed_history_prefixes
        [Dir.pwd, File.join(Dir.home, '.local', 'share', 'skill_bench')]
      end
      private_class_method :allowed_history_prefixes

      # Writes data atomically using a temp file and rename.
      #
      # @param path [String] target file path
      # @param data [Object] data to serialize as JSON
      # @return [void]
      def self.atomic_write(path, data)
        dir = File.dirname(path)
        FileUtils.mkpath(dir)

        temp_path = "#{path}.tmp.#{Process.pid}"
        File.open(temp_path, File::WRONLY | File::CREAT | File::TRUNC, 0o644) do |f|
          f.flock(File::LOCK_EX)
          f.write(JSON.pretty_generate(data))
          f.fsync
        end
        File.rename(temp_path, path)
      end
      private_class_method :atomic_write
    end
  end
end
