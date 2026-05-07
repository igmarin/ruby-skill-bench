# frozen_string_literal: true

require 'test_helper'

module AgentEval
  module Commands
    class EvalNewTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('eval_new_test')
        Dir.chdir(@tmp_dir)
        FileUtils.mkdir('evals')
      end

      def teardown
        Dir.chdir('/')
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_run_creates_generic_eval
        EvalNew.run(name: 'my-eval')

        assert_path_exists 'evals/my-eval/task.md'
        assert_path_exists 'evals/my-eval/criteria.json'
        refute_path_exists 'evals/my-eval/rails_helper.rb'
      end

      def test_run_creates_rails_eval
        EvalNew.run(name: 'my-eval', runtime: 'rails')

        assert_path_exists 'evals/my-eval/task.md'
        assert_path_exists 'evals/my-eval/criteria.json'
        assert_path_exists 'evals/my-eval/rails_helper.rb'
      end

      def test_task_template
        template = EvalNew.task_template('test-eval')

        assert_includes template, '# Eval: test-eval'
        assert_includes template, '## Task'
        assert_includes template, '## Success Criteria'
      end

      def test_default_criteria_generic
        criteria = EvalNew.default_criteria('generic')

        assert_equal 'generic', criteria[:runtime]
        assert_in_delta(0.8, criteria[:pass]['score_threshold'])
        assert_in_delta(0.5, criteria[:fail]['score_threshold'])
      end

      def test_default_criteria_rails
        criteria = EvalNew.default_criteria('rails')

        assert_equal 'rails', criteria[:runtime]
      end

      def test_criteria_json_is_valid_json
        eval_path = File.join(@tmp_dir, 'evals', 'test-eval')
        FileUtils.mkpath(eval_path)

        EvalNew.create_criteria_json(eval_path, 'generic')
        content = File.read(File.join(eval_path, 'criteria.json'))
        parsed = JSON.parse(content)

        assert_equal 'generic', parsed['runtime']
      end
    end
  end
end
