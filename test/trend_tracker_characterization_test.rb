# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'stringio'

module SkillBench
  # Fake report struct for trend tracker tests.
  FakeReport = Struct.new(:verdict, :baseline_total, :context_total, :deltas, keyword_init: true)

  class TrendTrackerCharacterizationTest < Minitest::Test
    def setup
      @tmp_dir = Dir.mktmpdir('trend_tracker_char_test')
      @history_file = File.join(@tmp_dir, 'history.json')
      @tracker = TrendTracker.new(history_file: @history_file)

      @original_stderr = $stderr
      $stderr = StringIO.new
    end

    def teardown
      $stderr = @original_stderr
      FileUtils.rm_rf(@tmp_dir)
    end

    # Characterization test: Records evaluation result to history file
    def test_record_creates_history_file_with_correct_structure
      result = build_complete_result

      response = @tracker.record(result)

      assert response[:success]
      assert response[:response][:recorded]
      assert_path_exists @history_file

      history = JSON.parse(File.read(@history_file))

      assert_equal 1, history.size

      entry = history.first

      assert entry['timestamp']
      assert_equal 'test-eval', entry['eval_name']
      assert_equal %w[test-skill], entry['skill_names']
      assert entry['verdict']
      assert_equal 30, entry['baseline_total']
      assert_equal 80, entry['context_total']
    end

    # Characterization test: Handles file corruption with backup recovery.
    # The backup holds the PREVIOUS good version, so recovery must fall back to
    # it. A backup only exists once a second write has snapshotted the prior
    # file, hence two records before corrupting the main file.
    def test_load_history_handles_corruption_with_backup
      # First run: writes history, no .bak yet (nothing to back up).
      @tracker.record(build_complete_result(context_total: 80))
      # Second run: snapshots the previous version into .bak before writing.
      @tracker.record(build_complete_result(context_total: 90))

      # Corrupt main file
      File.write(@history_file, 'invalid json{')

      history = @tracker.history

      assert_equal 1, history.size
      assert_equal 'test-eval', history.first[:eval_name]
      assert_equal 80, history.first[:context_total] # recovered the previous good version
    end

    # Characterization test: Computes trend direction correctly
    def test_trend_for_computes_direction_and_deltas
      @tracker.record(build_complete_result(baseline_total: 30, context_total: 80))

      trend = @tracker.trend_for(build_complete_result(baseline_total: 35, context_total: 90))

      assert_equal :improved, trend[:baseline_trend]
      assert_equal :improved, trend[:context_trend]
      assert_equal 5, trend[:baseline_delta]
      assert_equal 10, trend[:context_delta]
      assert trend[:previous_run]
    end

    # Characterization test: Returns nil when no matching history exists
    def test_trend_for_returns_nil_without_matching_history
      @tracker.record(build_complete_result(eval_name: 'different-eval'))

      trend = @tracker.trend_for(build_complete_result(eval_name: 'test-eval'))

      assert_nil trend
    end

    # Characterization test: Only compares entries with same eval_name and skill_names
    def test_trend_for_filters_by_eval_and_skills
      @tracker.record(build_complete_result(eval_name: 'test-eval', skill_names: ['skill-a']))
      @tracker.record(build_complete_result(eval_name: 'test-eval', skill_names: ['skill-b']))

      trend = @tracker.trend_for(build_complete_result(eval_name: 'test-eval', skill_names: ['skill-a']))

      assert_equal :unchanged, trend[:context_trend] # Matches first entry
    end

    # Characterization test: Handles corruption when both main and backup are corrupt
    def test_load_history_returns_empty_when_both_corrupted
      @tracker.record(build_complete_result)

      File.write(@history_file, 'invalid json{')
      File.write("#{@history_file}.bak", 'also invalid{')

      history = @tracker.history

      assert_equal [], history
      assert_match(/History file .* corrupted/, $stderr.string)
    end

    # Characterization test: Error handling during recording
    def test_record_handles_errors_gracefully
      # Make file unwritable
      FileUtils.chmod(0o444, @tmp_dir)

      response = @tracker.record(build_complete_result)

      refute response[:success]
      assert response[:response][:error][:message]
    ensure
      FileUtils.chmod(0o755, @tmp_dir)
    end

    private

    def build_complete_result(baseline_total: 30, context_total: 80, eval_name: 'test-eval', skill_names: ['test-skill'])
      {
        success: true,
        eval_name: eval_name,
        skill_names: skill_names,
        response: {
          report: FakeReport.new(
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
