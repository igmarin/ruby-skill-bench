# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/agent_eval/models/eval'
require 'json'

RSpec.describe AgentEval::Models::Eval do
  describe '.load' do
    it 'loads an eval from a directory path' do
      eval = described_class.load('evals/test-eval')
      expect(eval).to be_a(described_class)
      expect(eval.name).to eq('test-eval')
    end
  end

  describe '#criteria' do
    it 'loads criteria from criteria.json' do
      eval = described_class.new(name: 'test-eval', path: 'evals/test-eval')
      expect(eval.criteria).to be_a(Hash)
    end
  end
end
