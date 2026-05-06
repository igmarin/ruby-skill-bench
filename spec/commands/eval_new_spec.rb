# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/agent_eval/commands/eval_new'

RSpec.describe AgentEval::Commands::EvalNew do
  describe '.run' do
    it 'creates generic eval with task.md and criteria.json' do
      described_class.run(name: 'test-eval', runtime: 'generic')
      expect(File).to exist('evals/test-eval/task.md')
      expect(File).to exist('evals/test-eval/criteria.json')
    end

    it 'creates rails eval with rails-specific files' do
      described_class.run(name: 'rails-eval', runtime: 'rails')
      expect(File).to exist('evals/rails-eval/task.md')
    end
  end
end
