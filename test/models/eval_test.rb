# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Models
    class EvalTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('eval_test')
      end

      def teardown
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_loads_eval_with_criteria_object
        eval_dir = File.join(@tmp_dir, 'test-eval')
        FileUtils.mkdir_p(eval_dir)
        File.write(File.join(eval_dir, 'task.md'), 'Test task')
        File.write(File.join(eval_dir, 'criteria.json'), valid_criteria_json)

        eval = Eval.load(eval_dir)

        assert_equal 'test-eval', eval.name
        assert_equal 'Test task', eval.task
        assert_instance_of SkillBench::Criteria, eval.criteria
        assert_equal 5, eval.criteria.dimensions.size
        assert_equal 70, eval.criteria.pass_threshold
        assert_equal 10, eval.criteria.minimum_delta
      end

      def test_loads_eval_without_criteria
        eval_dir = File.join(@tmp_dir, 'test-eval')
        FileUtils.mkdir_p(eval_dir)
        File.write(File.join(eval_dir, 'task.md'), 'Test task')

        eval = Eval.load(eval_dir)

        assert_equal 'test-eval', eval.name
        assert_equal 'Test task', eval.task
        assert_instance_of SkillBench::Criteria, eval.criteria
        assert_equal [], eval.criteria.dimensions
      end

      def test_raises_when_directory_missing
        assert_raises(Errno::ENOENT) do
          Eval.load(File.join(@tmp_dir, 'nonexistent'))
        end
      end

      def test_loads_metadata_when_metadata_json_exists
        eval_dir = File.join(@tmp_dir, 'test-eval')
        FileUtils.mkdir_p(eval_dir)
        File.write(File.join(eval_dir, 'task.md'), 'Test task')
        File.write(File.join(eval_dir, 'criteria.json'), valid_criteria_json)
        File.write(File.join(eval_dir, 'metadata.json'), {
          'id' => 'test-eval',
          'context_mode' => 'skill_bundle_xml',
          'requires_companion_resources' => true
        }.to_json)

        eval = Eval.load(eval_dir)

        assert_equal 'skill_bundle_xml', eval.metadata['context_mode']
        assert eval.metadata['requires_companion_resources']
        assert_equal 'test-eval', eval.metadata['id']
      end

      def test_returns_empty_hash_when_metadata_json_missing
        eval_dir = File.join(@tmp_dir, 'test-eval')
        FileUtils.mkdir_p(eval_dir)
        File.write(File.join(eval_dir, 'task.md'), 'Test task')
        File.write(File.join(eval_dir, 'criteria.json'), valid_criteria_json)

        eval = Eval.load(eval_dir)

        assert_equal({}, eval.metadata)
      end

      def test_raises_on_malformed_metadata_json
        eval_dir = File.join(@tmp_dir, 'test-eval')
        FileUtils.mkdir_p(eval_dir)
        File.write(File.join(eval_dir, 'task.md'), 'Test task')
        File.write(File.join(eval_dir, 'criteria.json'), valid_criteria_json)
        File.write(File.join(eval_dir, 'metadata.json'), '{invalid json}')

        assert_raises(JSON::ParserError) do
          Eval.load(eval_dir)
        end
      end

      private

      def valid_criteria_json
        {
          context: 'Evaluate API',
          dimensions: [
            { name: 'correctness', max_score: 30 },
            { name: 'skill_adherence', max_score: 25 },
            { name: 'code_quality', max_score: 20 },
            { name: 'test_coverage', max_score: 15 },
            { name: 'documentation', max_score: 10 }
          ],
          pass_threshold: 70,
          minimum_delta: 10
        }.to_json
      end
    end
  end
end
