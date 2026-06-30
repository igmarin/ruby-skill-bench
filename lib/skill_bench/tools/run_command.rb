# frozen_string_literal: true

require 'open3'
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

      # Seconds to wait after SIGTERM before escalating to SIGKILL when a command
      # exceeds its execution deadline.
      TERM_GRACE_PERIOD = 2

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

        return "Error: Command '#{base_cmd}' arguments are not permitted by the configured argument constraints." unless arguments_permitted?(base_cmd, argv)

        return HOST_EXECUTION_REFUSED unless container_id || SkillBench::Config.allow_host_execution

        warn_unisolated_host_execution unless container_id
        execute(argv, working_dir_path, container_id)
      end

      # Checks the command's arguments against the optional, per-command
      # argument constraints from configuration.
      #
      # This is a default-off seam: the command allowlist remains the primary
      # authorization control, and any allowlisted wrapper binary still grants
      # broad host execution. When no constraints are configured (the default),
      # or none apply to +base_cmd+, every argument is permitted so behavior is
      # unchanged. When a constraint exists for +base_cmd+, the command is
      # refused if any argument contains a disallowed substring/flag.
      #
      # @param base_cmd [String] The base command (first token of the command).
      # @param argv [Array<String>] The tokenized command and arguments.
      # @return [Boolean] true when the arguments are permitted to run.
      def self.arguments_permitted?(base_cmd, argv)
        constraints = SkillBench::Config.command_argument_constraints
        return true if constraints.nil? || constraints.empty?

        # Constraint keys may be strings (facade API) or symbols (loaded from
        # JSON via symbolize_names), so look the command up under both.
        disallowed = constraints[base_cmd] || constraints[base_cmd.to_sym]
        return true if disallowed.nil? || disallowed.empty?

        argv.drop(1).none? { |arg| disallowed.any? { |bad| arg.include?(bad.to_s) } }
      end
      private_class_method :arguments_permitted?

      # Runs the resolved command and formats its result, enforcing the
      # configured execution timeout.
      #
      # The command is spawned in its own process group so that, on timeout, the
      # whole group (the command and any children it forked) can be signalled —
      # something `Timeout.timeout` around `Open3.capture3` could not do, because
      # `capture3`'s `ensure` blocks on `wait_thr.value` and never signals the
      # child.
      #
      # @param argv [Array<String>] The tokenized command and arguments.
      # @param working_dir_path [Pathname] The host directory for host execution.
      # @param container_id [String, nil] The Docker container ID for isolated execution.
      # @return [String] Formatted exit status, STDOUT, and STDERR, or a timeout message.
      def self.execute(argv, working_dir_path, container_id)
        max_time = SkillBench::Config.max_execution_time
        command, spawn_opts = resolve_invocation(argv, working_dir_path, container_id)
        result = capture(command, spawn_opts, max_time)
        return "Error: Command execution timed out after #{max_time} seconds." if result == :timed_out

        stdout_str, stderr_str, status = result
        format_result(status, stdout_str, stderr_str)
      end
      private_class_method :execute

      # Formats the captured command output into the standard result string.
      #
      # @param status [Process::Status] The exit status of the command.
      # @param stdout_str [String] The captured standard output.
      # @param stderr_str [String] The captured standard error.
      # @return [String] Formatted exit status, STDOUT, and STDERR.
      def self.format_result(status, stdout_str, stderr_str)
        <<~RESULT
          Exit Status: #{status.exitstatus}
          STDOUT:
          #{stdout_str}
          STDERR:
          #{stderr_str}
        RESULT
      end
      private_class_method :format_result

      # Builds the command array and spawn options for either container or host
      # execution. Both run in their own process group (`pgroup: true`) so the
      # watchdog can kill the whole group on timeout.
      #
      # @param argv [Array<String>] The tokenized command and arguments.
      # @param working_dir_path [Pathname] The host directory for host execution.
      # @param container_id [String, nil] The Docker container ID for isolated execution.
      # @return [Array(Array<String>, Hash)] The full command array and spawn options.
      def self.resolve_invocation(argv, working_dir_path, container_id)
        return [['docker', 'exec', '-w', '/sandbox', container_id, *argv], { pgroup: true }] if container_id

        [argv, { chdir: working_dir_path.to_s, pgroup: true }]
      end
      private_class_method :resolve_invocation

      # Spawns the command, draining STDOUT/STDERR on separate threads so a chatty
      # or hung child never deadlocks the reader, and enforces the deadline with a
      # watchdog that kills the process group when the command overruns.
      #
      # @param command [Array<String>] The full command array (no shell).
      # @param spawn_opts [Hash] Options passed to the spawner (includes `pgroup`).
      # @param max_time [Integer] Maximum execution time in seconds.
      # @return [Array(String, String, Process::Status), Symbol] STDOUT, STDERR, and
      #   status on completion, or `:timed_out` when the deadline is exceeded.
      def self.capture(command, spawn_opts, max_time)
        Open3.popen3(*command, **spawn_opts) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          readers = [Thread.new { stdout.read }, Thread.new { stderr.read }]
          completed = wait_thr.join(max_time)
          terminate_process_group(wait_thr) unless completed
          stdout_str, stderr_str = readers.map(&:value)
          completed ? [stdout_str, stderr_str, wait_thr.value] : :timed_out
        end
      end
      private_class_method :capture

      # Terminates the command's entire process group: SIGTERM first, then SIGKILL
      # after a short grace period if it has not exited. Signalling the negated
      # process group id reaches the command and any children it forked.
      #
      # @param wait_thr [Process::Waiter] The wait thread for the spawned process group leader.
      # @return [void]
      def self.terminate_process_group(wait_thr)
        pgid = wait_thr.pid
        signal_group('TERM', pgid)
        signal_group('KILL', pgid) unless wait_thr.join(TERM_GRACE_PERIOD)
      end
      private_class_method :terminate_process_group

      # Sends a signal to a whole process group, ignoring an already-exited group.
      #
      # @param signal [String] The signal name (e.g. "TERM", "KILL").
      # @param pgid [Integer] The process group id (leader pid) to signal.
      # @return [void]
      def self.signal_group(signal, pgid)
        Process.kill(signal, -pgid)
      rescue Errno::ESRCH
        nil
      end
      private_class_method :signal_group

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
