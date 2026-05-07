# frozen_string_literal: true

require 'pathname'
require_relative 'read_file'
require_relative 'write_file'
require_relative 'run_command'
require_relative 'argument_parser'

module Evaluator
  module Tools
    # Dispatches tool execution based on the tool name, coordinating parsing and invocation.
    class Dispatcher
      # Executes a specified tool with the given arguments within a working directory.
      #
      # @param name [String] The name of the tool to execute (e.g., 'read_file').
      # @param arguments [String] A JSON string containing the arguments for the tool.
      # @param working_dir [String] The base directory in which the tool should operate.
      # @param container_id [String, nil] The Docker container ID for isolated execution.
      # @return tool execution result or raises exception.
      # @raise [StandardError] when execution or argument parsing fails
      def self.call(name, arguments, working_dir, container_id = nil)
        args = ArgumentParser.call(arguments)
        return args if args.is_a?(Hash) && args[:success] == false

        working_dir_path = Pathname.new(working_dir).expand_path

        execute_tool(name, args, working_dir_path, container_id)
      rescue StandardError => e
        log_error(e)
        raise
      end

      class << self
        private

        def log_error(exception)
          msg = "#{exception.message}\n#{exception.backtrace.first(5).join("\n")}"
          if defined?(Rails)
            Rails.logger.error(msg)
          elsif !defined?(Minitest)
            warn("Dispatcher Error: #{msg}")
          end
        end

        def execute_tool(name, args, working_dir_path, container_id)
          path = args['path']
          case name
          when 'read_file'
            ReadFile.call(path, working_dir_path)
          when 'write_file'
            WriteFile.call(path, args['content'], working_dir_path)
          when 'run_command'
            RunCommand.call(args['command'], working_dir_path, container_id)
          else
            raise StandardError, "Unknown tool '#{name}'"
          end
        end
      end
    end
  end
end
