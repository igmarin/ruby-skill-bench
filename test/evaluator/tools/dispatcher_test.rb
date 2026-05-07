# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Tools
    # Tests for the Evaluator::Tools::Dispatcher
    class DispatcherTest < Minitest::Test
      def test_execute_read_file
        Evaluator::Tools::ReadFile.expects(:call).with('test.txt', anything).returns('file content')
        result = Dispatcher.call('read_file', '{"path":"test.txt"}', Dir.pwd, nil)

        assert_equal 'file content', result
      end

      def test_execute_write_file
        Evaluator::Tools::WriteFile.expects(:call).with('new_file.txt', 'New text', anything).returns('success')
        result = Dispatcher.call('write_file', '{"path":"new_file.txt", "content":"New text"}', Dir.pwd, nil)

        assert_equal 'success', result
      end

      def test_execute_run_command
        Evaluator::Tools::RunCommand.expects(:call).with('echo test', anything, nil).returns('command output')
        result = Dispatcher.call('run_command', '{"command":"echo test"}', Dir.pwd, nil)

        assert_equal 'command output', result
      end

      def test_execute_unknown_tool
        error = assert_raises(StandardError) do
          Dispatcher.call('unknown', '{}', Dir.pwd)
        end
        assert_match(/Unknown tool/, error.message)
      end

      def test_execute_rescues_standard_error
        Evaluator::Tools::ReadFile.expects(:call).raises(StandardError, 'Oops')
        error = assert_raises(StandardError) do
          Dispatcher.call('read_file', '{"path":"test.txt"}', Dir.pwd, nil)
        end
        assert_equal 'Oops', error.message
      end
    end
  end
end
