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

          # Nothing must be executed when fail-closed refusal triggers.
          Open3.expects(:capture3).never

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

          status = mock('Process::Status')
          status.stubs(:exitstatus).returns(0)
          Open3.expects(:capture3).with('echo', 'test', chdir: working_dir.to_s).returns(['test', '', status])

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

          # Mock Open3.capture3 to verify docker call
          status = mock('Process::Status')
          status.stubs(:exitstatus).returns(0)
          Open3.expects(:capture3).with('docker', 'exec', '-w', '/sandbox', container_id, 'echo', 'test').returns(['test', '', status])

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
    end
  end
end
