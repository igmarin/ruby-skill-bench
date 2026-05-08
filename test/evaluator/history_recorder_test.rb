# frozen_string_literal: true

require 'test_helper'
require 'stringio'

module SkillBench
  class HistoryRecorderTest < Minitest::Test
    def test_record_persists_entry_on_success
      results = {
        success: true,
        tasks: [{ judge_score: '{"baseline_score": 80, "context_score": 90}' }]
      }
      fixed_path = '/tmp/benchmarks.json'

      SkillBench::HistoryRecorder::PersistenceService.stubs(:determine_history_file).returns(fixed_path)
      SkillBench::HistoryRecorder::PersistenceService.stubs(:load_history).with(fixed_path).returns([])

      mock_file = mock('file')
      mock_file.expects(:flock).with(File::LOCK_EX)
      mock_file.expects(:write).with(regexp_matches(%r{"source_path": "skills/test"}))
      mock_file.expects(:fsync)

      File.expects(:open).with(regexp_matches(/\.tmp\.\d+/), File::WRONLY | File::CREAT | File::TRUNC, 0o644).yields(mock_file).returns(true)
      File.expects(:rename).with(regexp_matches(/\.tmp\.\d+/), fixed_path).returns(true)

      SkillBench::HistoryRecorder.record(results, source_path: 'skills/test', model: 'gpt-4')
    end

    def test_record_does_nothing_on_failure
      results = { success: false }
      File.expects(:open).never
      SkillBench::HistoryRecorder.record(results, source_path: 'test', model: 'gpt-4')
    end
  end
end
