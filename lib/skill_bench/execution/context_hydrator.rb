# frozen_string_literal: true

require 'pathname'
require 'cgi'
require_relative '../constants'

module SkillBench
  module Execution
    # Responsible for loading source context files from a given path
    # and wrapping them in XML tags for injection into the LLM system prompt.
    class ContextHydrator
      # Error message returned when context hydration fails.
      HYDRATION_FAILED = 'Failed to hydrate context from source path'

      # Immutable record pairing a context file's path with the content and byte
      # size captured during a single filesystem pass, so the total-size check and
      # the XML build can reuse them without a second `stat` or `read`.
      ContextFile = Struct.new(:path, :content, :bytesize)

      # Loads and formats source context files.
      #
      # @param params [Hash] The configuration for context hydration.
      # @option params [String] :source_path The path to the source directory containing readable files.
      # @option params [String] :skill_path Deprecated alias for `:source_path`.
      # @option params [Pathname, String] :base_path (optional) The base path to resolve the source directory against.
      # @return [Hash] A result hash with :success, and :response containing the XML formatted context.
      # @raise [TypeError] when the provided source or base path cannot be converted into a pathname.
      def self.call(params)
        new(**params).call
      end

      # @param source_path [String] The path to the source directory containing readable files.
      # @param skill_path [String] Deprecated alias for source_path.
      # @param base_path [Pathname, String] The base path to resolve the source directory against.
      # @return [void]
      # @raise [TypeError] when the provided source or base path cannot be converted into a pathname.
      def initialize(source_path: nil, skill_path: nil, base_path: nil)
        @source_path = source_path || skill_path
        @base_path = base_path || Pathname.new(Dir.pwd)
      end

      # Performs the hydration process.
      #
      # @return [Hash] The standardized result hash indicating success or failure.
      def call
        return missing_path_result unless @source_path

        full_path = @base_path.join(@source_path).expand_path
        base_expanded = @base_path.expand_path

        return missing_path_result unless within_base?(full_path, base_expanded)
        return missing_path_result unless full_path.exist? && full_path.directory?

        context_files = collect_context_files(full_path)
        return missing_path_result unless validate_total_size?(context_files)

        xml_context = build_xml(context_files)

        { success: true, response: { context: xml_context } }
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'Hydration Error')
        { success: false, response: { error: { message: e.message } } }
      end

      private

      # Determines whether the resolved path is contained within the base directory.
      # Uses a separator-aware boundary so a sibling directory whose name merely shares
      # the base directory's prefix (e.g. base `/tmp/foo` vs `/tmp/foo-evil`) is rejected.
      #
      # @param full_path [Pathname] The expanded source path to validate.
      # @param base_expanded [Pathname] The expanded base directory.
      # @return [Boolean] true when full_path is the base directory or a descendant of it.
      def within_base?(full_path, base_expanded)
        full = full_path.to_path
        base = base_expanded.to_path
        full == base || full.start_with?(base + File::SEPARATOR)
      end

      def missing_path_result
        { success: false, response: { error: { message: "Source path #{@source_path} does not exist or is not a directory" } } }
      end

      # Collects readable context files in a single filesystem pass. Symlinks are
      # rejected and oversized files are skipped via a cheap `File.size` pre-check
      # so a huge file is never read into memory; each surviving file is read
      # exactly once, capturing its content and byte size for downstream reuse.
      #
      # @param full_path [Pathname] The validated, in-base source directory.
      # @return [Array<ContextFile>] Sorted records of path, content, and byte size.
      def collect_context_files(full_path)
        pattern = full_path.join("*{#{Constants::ContextHydration::TEXT_EXTENSIONS.join(',')}}").to_s
        Dir.glob(pattern)
           .reject { |file_path| File.symlink?(file_path) }
           .select { |file_path| File.size(file_path) <= Constants::ContextHydration::MAX_FILE_SIZE }
           .map { |file_path| read_context_file(file_path) }
      end

      # Reads a single in-limit file once, pairing its content with the byte size
      # derived from that content so no second `stat` is required.
      #
      # @param file_path [String] Absolute path to an in-limit context file.
      # @return [ContextFile] The path, content, and byte size record.
      def read_context_file(file_path)
        content = File.read(file_path)
        ContextFile.new(file_path, content, content.bytesize)
      end

      # Validates that the combined byte size of the already-read context files
      # stays within the total-size cap, reusing the sizes captured during
      # collection instead of re-stat-ing each file.
      #
      # @param context_files [Array<ContextFile>] The collected context records.
      # @return [Boolean] true when the total size is within the cap.
      def validate_total_size?(context_files)
        total_size = context_files.sum(&:bytesize)
        return true if total_size <= Constants::ContextHydration::MAX_TOTAL_CONTEXT_SIZE

        SkillBench::ErrorLogger.log_error(
          StandardError.new("Total context size #{total_size} exceeds maximum #{Constants::ContextHydration::MAX_TOTAL_CONTEXT_SIZE}"),
          'ContextHydrator'
        )
        false
      end

      # Builds the XML structure wrapping the already-read context file contents.
      #
      # @param context_files [Array<ContextFile>] The collected context records.
      # @return [String] The combined XML representation of the file contents.
      def build_xml(context_files)
        return '' if context_files.empty?

        xml = ['<agent_context>']

        context_files.each do |context_file|
          relative_path = Pathname.new(context_file.path).relative_path_from(@base_path).to_s

          xml << "  <file path=\"#{CGI.escapeHTML(relative_path)}\">"
          xml << CGI.escapeHTML(context_file.content).gsub(/^/, '    ')
          xml << '  </file>'
        end

        xml << '</agent_context>'
        xml.join("\n")
      end
    end
  end
end
