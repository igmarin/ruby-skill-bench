# frozen_string_literal: true

require 'test_helper'

module SkillBench
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

        assert_equal 'Evaluate generic task', criteria[:context]
        assert_equal 5, criteria[:dimensions].size
        assert_equal(100, criteria[:dimensions].sum { |d| d[:max_score] })
        assert_equal 70, criteria[:pass_threshold]
        assert_equal 10, criteria[:minimum_delta]
      end

      def test_default_criteria_rails
        criteria = EvalNew.default_criteria('rails')

        assert_equal 'Evaluate rails task', criteria[:context]
      end

      def test_criteria_json_is_valid_json
        eval_path = File.join(@tmp_dir, 'evals', 'test-eval')
        FileUtils.mkpath(eval_path)

        EvalNew.create_criteria_json(eval_path, 'generic')
        content = File.read(File.join(eval_path, 'criteria.json'))
        parsed = JSON.parse(content)

        assert_equal 'Evaluate generic task', parsed['context']
        assert_equal 5, parsed['dimensions'].size
      end
    end
  end
end
