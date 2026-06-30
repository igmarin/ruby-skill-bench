# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  module Services
    class TrendRecorderServiceTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('trend_recorder_test')
        @history_file = File.join(@tmp_dir, 'trends.json')
        @eval_name = 'test-eval'
        @skill_names = ['test-skill']
        @result = {
          success: true,
          response: {
            report: Struct.new(:verdict, :baseline_total, :context_total, :deltas, keyword_init: true).new(
              verdict: true,
              baseline_total: 30,
              context_total: 80,
              deltas: { 'correctness' => 16 }
            )
          }
        }
      end

      def teardown
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_records_and_computes_trend
        TrendTracker.any_instance.stubs(:trend_for).returns({ delta: 5 })
        TrendTracker.any_instance.stubs(:record).returns({ success: true })

        result = TrendRecorderService.call(@result, @eval_name, @skill_names)

        assert result[:success]
        assert_equal({ delta: 5 }, result[:trend])
      end

      def test_call_returns_error_when_record_fails
        TrendTracker.any_instance.stubs(:trend_for).returns({})
        TrendTracker.any_instance.stubs(:record).returns({ success: false, error: { message: 'Record failed' } })

        result = TrendRecorderService.call(@result, @eval_name, @skill_names)

        refute result[:success]
        assert_includes result[:response][:error][:message], 'Trend tracking record failed'
      end

      def test_call_handles_unexpected_record_response
        TrendTracker.any_instance.stubs(:trend_for).returns({})
        TrendTracker.any_instance.stubs(:record).returns('unexpected')

        result = TrendRecorderService.call(@result, @eval_name, @skill_names)

        refute result[:success]
        assert_includes result[:response][:error][:message], 'Unexpected record response'
      end

      def test_call_handles_standard_error
        TrendTracker.any_instance.stubs(:trend_for).raises(StandardError, 'Trend error')

        result = TrendRecorderService.call(@result, @eval_name, @skill_names)

        refute result[:success]
        assert_includes result[:response][:error][:message], 'Trend error'
      end

      def test_call_extracts_error_message_from_hash
        TrendTracker.any_instance.stubs(:trend_for).returns({})
        TrendTracker.any_instance.stubs(:record).returns(
          success: false,
          response: { error: { message: 'Specific error' } }
        )

        result = TrendRecorderService.call(@result, @eval_name, @skill_names)

        refute result[:success]
        assert_includes result[:response][:error][:message], 'Specific error'
      end

      # End-to-end against a real history file: the run must load history only
      # once (no duplicate parse), compute the trend against the previous run,
      # and append the new entry.
      def test_call_loads_history_once_and_records_with_trend
        tracker = TrendTracker.new(history_file: @history_file)
        TrendTracker.stubs(:new).returns(tracker)
        tracker.record(report_result(context_total: 80).merge(eval_name: @eval_name, skill_names: @skill_names))

        persistence = tracker.instance_variable_get(:@persistence)
        load_calls = 0
        original_load = persistence.method(:load)
        persistence.define_singleton_method(:load) do
          load_calls += 1
          original_load.call
        end

        result = TrendRecorderService.call(report_result(context_total: 95), @eval_name, @skill_names)

        assert result[:success]
        assert_equal :improved, result[:trend][:context_trend]
        assert_equal 15, result[:trend][:context_delta]
        assert_equal 1, load_calls, 'history should be loaded exactly once per run'

        history = JSON.parse(File.read(@history_file), symbolize_names: true)

        assert_equal 2, history.size
      end

      private

      def report_result(baseline_total: 30, context_total: 80)
        {
          success: true,
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
end
