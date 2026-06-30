# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  class TrendTrackerTest < Minitest::Test
    def setup
      @tmp_dir = Dir.mktmpdir('trend_tracker_test')
      @history_file = File.join(@tmp_dir, 'history.json')
    end

    def teardown
      FileUtils.rm_rf(@tmp_dir)
    end

    def test_records_eval_result
      tracker = TrendTracker.new(history_file: @history_file)
      result = build_result

      record = tracker.record(result)

      assert record[:success]
      assert_path_exists @history_file
    end

    def test_loads_previous_runs
      tracker = TrendTracker.new(history_file: @history_file)
      tracker.record(build_result(baseline_total: 30, context_total: 80))
      tracker.record(build_result(baseline_total: 35, context_total: 85))

      history = tracker.history

      assert_equal 2, history.size
    end

    def test_computes_trend_against_previous
      tracker = TrendTracker.new(history_file: @history_file)
      tracker.record(build_result(baseline_total: 30, context_total: 80))

      trend = tracker.trend_for(build_result(baseline_total: 35, context_total: 90))

      assert_equal :improved, trend[:context_trend]
      assert_equal 10, trend[:context_delta]
      assert_equal 5, trend[:baseline_delta]
    end

    def test_computes_trend_unchanged
      tracker = TrendTracker.new(history_file: @history_file)
      tracker.record(build_result(baseline_total: 30, context_total: 80))

      trend = tracker.trend_for(build_result(baseline_total: 30, context_total: 80))

      assert_equal :unchanged, trend[:context_trend]
    end

    def test_returns_no_trend_when_no_history
      tracker = TrendTracker.new(history_file: @history_file)

      trend = tracker.trend_for(build_result)

      assert_nil trend
    end

    def test_only_compares_runs_for_same_eval_and_skill
      tracker = TrendTracker.new(history_file: @history_file)
      tracker.record(build_result(eval_name: 'eval-a', skill_names: ['skill-a'], context_total: 80))
      tracker.record(build_result(eval_name: 'eval-b', skill_names: ['skill-b'], context_total: 50))

      trend = tracker.trend_for(build_result(eval_name: 'eval-a', skill_names: ['skill-a'], context_total: 90))

      assert_equal :improved, trend[:context_trend]
      assert_equal 10, trend[:context_delta]
    end

    def test_returns_no_trend_when_no_matching_eval_or_skill
      tracker = TrendTracker.new(history_file: @history_file)
      tracker.record(build_result(eval_name: 'eval-a', skill_names: ['skill-a'], context_total: 80))

      trend = tracker.trend_for(build_result(eval_name: 'eval-b', skill_names: ['skill-b'], context_total: 90))

      assert_nil trend
    end

    def test_first_write_creates_no_backup
      tracker = TrendTracker.new(history_file: @history_file)

      result = tracker.record(build_result)

      assert result[:success]
      refute_path_exists "#{@history_file}.bak", 'first run has no previous version to back up'
    end

    def test_backup_holds_previous_version_not_current
      tracker = TrendTracker.new(history_file: @history_file)
      tracker.record(build_result(context_total: 80))
      tracker.record(build_result(context_total: 90))

      main = JSON.parse(File.read(@history_file), symbolize_names: true)
      backup = JSON.parse(File.read("#{@history_file}.bak"), symbolize_names: true)

      assert_equal 2, main.size
      assert_equal 1, backup.size
      assert_equal 80, backup.first[:context_total]
    end

    private

    def build_result(baseline_total: 30, context_total: 80, eval_name: 'test-eval', skill_names: ['test-skill'])
      {
        success: true,
        eval_name: eval_name,
        skill_names: skill_names,
        response: {
          report: Struct.new(:verdict, :baseline_total, :context_total, :deltas, keyword_init: true).new(
            verdict: true,
            baseline_total: baseline_total,
            context_total: context_total,
            deltas: { 'correctness' => 16 }
          )
        }
      }
    end
  end
end
