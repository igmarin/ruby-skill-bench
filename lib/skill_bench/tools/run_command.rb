# frozen_string_literal: true

require 'open3'
require 'timeout'
require 'shellwords'
require_relative '../config'
require_relative '../constants'
require_relative '../error_logger'

module SkillBench
  module Tools
    # Handles executing a shell command within the working directory.
    #
    # Real container isolation is not yet shipped, so an active sandbox means a
    # temporary git directory on the host. To honor the documented security
    # model the tool fails closed: when no container isolation is active it
    # refuses to run unless `allow_host_execution` is explicitly enabled.
    class RunCommand
      # Refusal returned when no container isolation is active and host execution
      # has not been explicitly enabled. Deliberately omits the allowlist.
      HOST_EXECUTION_REFUSED = 'Command execution refused: no sandbox isolation is active and ' \
                               "'allow_host_execution' is not enabled. Set \"allow_host_execution\": true in " \
                               'skill-bench.json to permit running commands directly on the host (NOT isolated).'

      # Warning emitted when a command runs un-isolated on the host because
      # `allow_host_execution` is enabled and no container is active.
      HOST_EXECUTION_WARNING = 'Warning: running command directly on the host with NO sandbox isolation ' \
                               '(allow_host_execution is enabled). Commands are not isolated from your machine.'

      # @return [Hash] The tool definition for the LLM API.
      def self.definition
        {
          type: 'function',
          function: {
            name: 'run_command',
            description: 'Execute a shell command (e.g., rspec).',
            parameters: {
              type: 'object',
              properties: {
                command: { type: 'string', description: 'The shell command to run.' }
              },
              required: ['command'],
              additionalProperties: false
            }
          }
        }
      end

      # Executes a shell command within the working directory (host or container).
      #
      # Tokenizes the command string before execution so that arguments are passed
      # directly to the OS without shell interpretation, preventing shell injection.
      #
      # Fails closed: when no container isolation is active (`container_id` is nil)
      # and `allow_host_execution` is false, the command is refused and nothing
      # runs. When host execution is explicitly allowed, a warning is emitted once
      # per command before running un-isolated on the host.
      #
      # @param command [String] The command to run (e.g. "rspec spec/models").
      # @param working_dir_path [Pathname] The host directory (ignored if container_id present).
      # @param container_id [String, nil] The Docker container ID for isolated execution.
      # @return [String] A formatted string containing the exit status, STDOUT, and STDERR,
      #   or a standardized error/refusal message.
      def self.call(command, working_dir_path, container_id = nil)
        argv = command.shellsplit
        return 'Error: Empty command.' if argv.empty?

        base_cmd = argv.first
        return "Error: Command '#{base_cmd}' is blocked for security reasons." if Constants::Tools::DANGEROUS_COMMANDS.include?(base_cmd)

        allowed = SkillBench::Config.allowed_commands
        return 'Error: No allowed commands configured. Set allowed_commands in skill-bench.json or use --mode mock.' if allowed.nil?
        return "Error: Command '#{base_cmd}' is not permitted." unless allowed.include?(base_cmd)

        return HOST_EXECUTION_REFUSED unless container_id || SkillBench::Config.allow_host_execution

        warn_unisolated_host_execution unless container_id
        execute(argv, working_dir_path, container_id)
      end

      # Runs the resolved command and formats its result, enforcing the
      # configured execution timeout.
      #
      # @param argv [Array<String>] The tokenized command and arguments.
      # @param working_dir_path [Pathname] The host directory for host execution.
      # @param container_id [String, nil] The Docker container ID for isolated execution.
      # @return [String] Formatted exit status, STDOUT, and STDERR, or a timeout message.
      def self.execute(argv, working_dir_path, container_id)
        max_time = SkillBench::Config.max_execution_time
        Timeout.timeout(max_time) do
          stdout_str, stderr_str, status = capture(argv, working_dir_path, container_id)
          <<~RESULT
            Exit Status: #{status.exitstatus}
            STDOUT:
            #{stdout_str}
            STDERR:
            #{stderr_str}
          RESULT
        end
      rescue Timeout::Error
        "Error: Command execution timed out after #{max_time} seconds."
      end
      private_class_method :execute

      # Captures the command output, in the container when one is active or on
      # the host otherwise.
      #
      # @param argv [Array<String>] The tokenized command and arguments.
      # @param working_dir_path [Pathname] The host directory for host execution.
      # @param container_id [String, nil] The Docker container ID for isolated execution.
      # @return [Array(String, String, Process::Status)] STDOUT, STDERR, and status.
      def self.capture(argv, working_dir_path, container_id)
        if container_id
          Open3.capture3('docker', 'exec', '-w', '/sandbox', container_id, *argv)
        else
          Open3.capture3(*argv, chdir: working_dir_path.to_s)
        end
      end
      private_class_method :capture

      # Emits a single warning that the command will run un-isolated on the host,
      # honoring the test-suite stderr suppression convention.
      #
      # @return [void]
      def self.warn_unisolated_host_execution
        return if SkillBench::ErrorLogger.skip_stderr_output?

        warn(HOST_EXECUTION_WARNING)
      end
      private_class_method :warn_unisolated_host_execution
    end
  end
end
