# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Tools
    # Tests for SkillBench::Tools::RunCommand
    class RunCommandTest < Minitest::Test
      def setup
        # Reset config to allow echo command
        SkillBench::Config.reset
        SkillBench::Config.allowed_commands = %w[echo]
      end

      def test_call_executes_command
        # Host execution is refused by default; opt in explicitly for this test.
        SkillBench::Config.allow_host_execution = true

        Dir.mktmpdir do |dir|
          working_dir = Pathname.new(dir).expand_path

          result = RunCommand.call('echo test', working_dir)

          assert_match(/STDOUT:\ntest/, result)
          assert_match(/Exit Status: 0/, result)
        end
      end

      def test_call_refuses_host_execution_when_not_isolated_and_not_allowed
        Dir.mktmpdir do |dir|
          working_dir = Pathname.new(dir).expand_path

          # Nothing must be spawned when the fail-closed refusal triggers.
          Open3.expects(:popen3).never

          result = RunCommand.call('echo test', working_dir)

          assert_match(/Command execution refused/, result)
          assert_match(/allow_host_execution/, result)
          # The refusal must not leak the configured allowlist.
          refute_match(/echo/, result)
        end
      end

      def test_call_executes_on_host_with_warning_when_explicitly_allowed
        SkillBench::Config.allow_host_execution = true

        Dir.mktmpdir do |dir|
          working_dir = Pathname.new(dir).expand_path

          result = nil
          _out, err = capture_io do
            result = RunCommand.call('echo test', working_dir)
          end

          assert_match(/STDOUT:\ntest/, result)
          assert_match(/Exit Status: 0/, result)
          assert_match(/no sandbox isolation/i, err)
          assert_match(/host/i, err)
        end
      end

      def test_call_executes_in_container
        Dir.mktmpdir do |dir|
          working_dir = Pathname.new(dir).expand_path
          container_id = 'mock-container-id'

          # Stub the spawn/watchdog seam to verify the docker invocation is built
          # correctly without requiring a real Docker daemon.
          status = mock('Process::Status')
          status.stubs(:exitstatus).returns(0)
          RunCommand.expects(:capture)
                    .with(['docker', 'exec', '-w', '/sandbox', container_id, 'echo', 'test'], { pgroup: true }, SkillBench::Config.max_execution_time)
                    .returns(['test', '', status])

          result = nil
          _out, err = capture_io do
            result = RunCommand.call('echo test', working_dir, container_id)
          end

          assert_match(/STDOUT:\ntest/, result)
          assert_match(/Exit Status: 0/, result)
          # Container execution is isolated: no host-execution warning is emitted.
          assert_empty err
        end
      end

      def test_call_runs_with_args_when_no_argument_constraints_configured
        # Default (no command_argument_constraints) leaves behavior unchanged.
        SkillBench::Config.allow_host_execution = true

        Dir.mktmpdir do |dir|
          working_dir = Pathname.new(dir).expand_path

          result = RunCommand.call('echo hello world', working_dir)

          assert_match(/STDOUT:\nhello world/, result)
          assert_match(/Exit Status: 0/, result)
        end
      end

      def test_call_refuses_command_whose_args_hit_configured_constraint
        SkillBench::Config.allow_host_execution = true
        SkillBench::Config.command_argument_constraints = { 'echo' => ['-n'] }

        Dir.mktmpdir do |dir|
          working_dir = Pathname.new(dir).expand_path

          # The constraint must block before anything is executed.
          Open3.expects(:capture3).never

          result = RunCommand.call('echo -n test', working_dir)

          assert_equal(
            "Error: Command 'echo' arguments are not permitted by the configured argument constraints.",
            result
          )
        end
      end

      def test_call_runs_when_constrained_command_has_clean_args
        SkillBench::Config.allow_host_execution = true
        SkillBench::Config.command_argument_constraints = { 'echo' => ['-n'] }

        Dir.mktmpdir do |dir|
          working_dir = Pathname.new(dir).expand_path

          result = RunCommand.call('echo hello', working_dir)

          assert_match(/STDOUT:\nhello/, result)
          assert_match(/Exit Status: 0/, result)
        end
      end

      def test_call_returns_timeout_result_without_waiting_for_full_runtime
        SkillBench::Config.allow_host_execution = true
        SkillBench::Config.allowed_commands = %w[sleep]
        SkillBench::Config.max_execution_time = 1

        Dir.mktmpdir do |dir|
          working_dir = Pathname.new(dir).expand_path

          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          result = RunCommand.call('sleep 30', working_dir)
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

          # Same timeout shape as before — keyed on by callers/tests.
          assert_equal 'Error: Command execution timed out after 1 seconds.', result.strip
          # The watchdog must return shortly after the deadline rather than
          # blocking on the child for the full 30s sleep (the old bug).
          assert_operator elapsed, :<, 10, 'timeout must not block for the full child runtime'
        end
      end

      def test_call_kills_runaway_child_process_on_timeout
        SkillBench::Config.allow_host_execution = true
        SkillBench::Config.allowed_commands = %w[sleep]
        SkillBench::Config.max_execution_time = 1

        Dir.mktmpdir do |dir|
          working_dir = Pathname.new(dir).expand_path

          result = RunCommand.call('sleep 30', working_dir)

          assert_match(/timed out after 1 seconds/, result)
          # Proof the child is actually terminated and reaped: no lingering
          # `sleep` child remains under this process after the call returns.
          lingering = `pgrep -P #{Process.pid} sleep`.split

          assert_empty lingering, 'the runaway sleep child must be killed and reaped on timeout'
        end
      end

      def test_call_enforces_argument_constraints_loaded_from_json_config
        config = {
          provider: 'mock',
          allowed_commands: %w[echo],
          allow_host_execution: true,
          command_argument_constraints: { 'echo' => ['-n'] }
        }

        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            File.write('skill-bench.json', JSON.generate(config))
            SkillBench::Config.reset

            working_dir = Pathname.new(dir).expand_path

            # The constraint loaded from skill-bench.json (symbol-keyed after
            # symbolize_names) must block execution before anything is spawned.
            Open3.expects(:popen3).never
            result = RunCommand.call('echo -n test', working_dir)

            assert_equal(
              "Error: Command 'echo' arguments are not permitted by the configured argument constraints.",
              result
            )
          end
        end
      end
    end
  end
end
