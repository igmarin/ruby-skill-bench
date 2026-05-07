# frozen_string_literal: true

require 'test_helper'

module AgentEval
  module Commands
    class InitTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('agent_eval_init_test')
        Dir.chdir(@tmp_dir)
      end

      def teardown
        Dir.chdir('/')
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_run_creates_config_file
        Init.run(rails: false, force: false)

        assert_path_exists '.agent-eval.yml'
      end

      def test_run_creates_rails_config
        Init.run(rails: true, force: false)

        assert_path_exists '.agent-eval.yml'
        content = File.read('.agent-eval.yml')

        assert_includes content, 'rails'
      end

      def test_run_raises_when_file_exists_and_not_force
        File.write('.agent-eval.yml', 'existing')

        assert_raises(RuntimeError) { Init.run(rails: false, force: false) }
      end

      def test_run_overwrites_when_force_true
        File.write('.agent-eval.yml', 'existing')

        Init.run(rails: false, force: true)

        refute_equal 'existing', File.read('.agent-eval.yml')
      end
    end
  end
end
