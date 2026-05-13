# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Agent
    class SummaryTest < Minitest::Test
      def test_builds_summary_from_result_hash
        result = Summary.call(
          files_changed: ['app/models/user.rb', 'spec/models/user_spec.rb'],
          commands_run: ['rails g model User', 'rspec'],
          agent_reasoning: 'I created the User model and added tests'
        )

        assert result[:success]
        summary = result[:response][:agent_summary]

        assert_equal ['app/models/user.rb', 'spec/models/user_spec.rb'], summary.files_changed
        assert_equal ['rails g model User', 'rspec'], summary.commands_run
        assert_equal 'I created the User model and added tests', summary.agent_reasoning
      end

      def test_builds_summary_with_defaults
        result = Summary.call

        assert result[:success]
        summary = result[:response][:agent_summary]

        assert_equal [], summary.files_changed
        assert_equal [], summary.commands_run
        assert_equal '', summary.agent_reasoning
      end
    end
  end
end
