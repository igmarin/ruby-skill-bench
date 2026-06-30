# frozen_string_literal: true

require 'json'
require 'pathname'
require 'fileutils'

module SkillBench
  class TrendTracker
    # Handles history file persistence operations including backup management
    class Persistence
      # @param history_file [String] Path to the history JSON file
      def initialize(history_file)
        @history_file = File.expand_path(history_file)
      end

      # Loads history from file with corruption recovery
      #
      # @return [Array<Hash>] List of historical entries
      def load
        return [] unless File.exist?(history_file)

        JSON.parse(File.read(history_file), symbolize_names: true)
      rescue JSON::ParserError => e
        backup = read_backup
        return backup if backup

        SkillBench::ErrorLogger.log_error(e, "History file #{history_file} corrupted")
        []
      end

      # Writes history to file atomically, snapshotting the previous good
      # version into the backup first.
      #
      # The existing history file (if any) is copied to +#{history_file}.bak+
      # before the new content is written, so the backup always holds the
      # previous good version rather than a duplicate of the current file. The
      # new content is serialized once and written via a temp-file + rename so
      # the main file is never left partially written. Returns a result hash so
      # callers do not need to rescue SystemCallError.
      #
      # @param history [Array<Hash>] History entries to write
      # @return [Hash] { success: true } on success, { success: false, error: { message: '...' } } on failure
      def write(history)
        backup_previous_version
        temp_file = "#{history_file}.tmp"
        File.write(temp_file, JSON.pretty_generate(history))
        File.rename(temp_file, history_file)

        { success: true }
      rescue SystemCallError => e
        { success: false, error: { message: e.message } }
      end

      private

      attr_reader :history_file

      # Copies the current history file to the backup path so the backup keeps
      # the previous good version. No-op on the first run when no history file
      # exists yet. A failed copy is non-fatal: it warns and lets the main
      # write proceed.
      #
      # @return [void]
      def backup_previous_version
        source = history_file
        return unless File.exist?(source)

        FileUtils.cp(source, "#{source}.bak")
      rescue SystemCallError => e
        warn "Backup copy failed for #{source}: #{e.message}"
      end

      # Reads backup file if it exists
      #
      # @return [Array<Hash>, nil] Backup data or nil if unavailable
      def read_backup
        backup_path = "#{history_file}.bak"
        return nil unless File.exist?(backup_path)

        JSON.parse(File.read(backup_path), symbolize_names: true)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
