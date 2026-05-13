# frozen_string_literal: true

require 'pathname'
require 'cgi'

module SkillBench
  module Execution
    # Responsible for loading source context files from a given path
    # and wrapping them in XML tags for injection into the LLM system prompt.
    class ContextHydrator
      # Error message returned when context hydration fails.
      HYDRATION_FAILED = 'Failed to hydrate context from source path'
      # File extensions considered for context hydration.
      TEXT_EXTENSIONS = %w[.md .rb .json .yml .yaml .txt].freeze
      # Maximum file size (in bytes) for files included in context hydration.
      MAX_FILE_SIZE = 50_000

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

        return missing_path_result unless full_path.to_path.start_with?(base_expanded.to_path)
        return missing_path_result unless full_path.exist? && full_path.directory?

        context_files = collect_context_files(full_path)
        xml_context = build_xml(context_files)

        { success: true, response: { context: xml_context } }
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'Hydration Error')
        { success: false, response: { error: { message: e.message } } }
      end

      private

      def missing_path_result
        { success: false, response: { error: { message: "Source path #{@source_path} does not exist or is not a directory" } } }
      end

      def collect_context_files(full_path)
        pattern = full_path.join("*{#{TEXT_EXTENSIONS.join(',')}}").to_s
        Dir.glob(pattern).reject { |f| File.symlink?(f) }
                         .select { |f| File.size(f) <= MAX_FILE_SIZE }
                         .sort
      end

      # Builds the XML structure wrapping the contents of the context files.
      #
      # @param context_files [Array<String>] List of absolute paths to context files.
      # @return [String] The combined XML representation of the file contents.
      def build_xml(context_files)
        return '' if context_files.empty?

        xml = ['<agent_context>']

        context_files.each do |file_path|
          relative_path = Pathname.new(file_path).relative_path_from(@base_path).to_s
          content = File.read(file_path)

          xml << "  <file path=\"#{CGI.escapeHTML(relative_path)}\">"
          xml << CGI.escapeHTML(content).gsub(/^/, '    ')
          xml << '  </file>'
        end

        xml << '</agent_context>'
        xml.join("\n")
      end
    end
  end
end
