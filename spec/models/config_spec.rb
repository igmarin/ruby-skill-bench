# frozen_string_literal: true

require 'rspec'
require 'yaml'
require_relative '../../lib/agent_eval/models/config'

RSpec.describe AgentEval::Models::Config do
  describe '.load' do
    it 'loads configuration from .agent-eval.yml by default' do
      config = described_class.load
      expect(config).to be_a(described_class)
      expect(config.providers).to be_a(Hash)
    end

    it 'accepts custom config path via parameter' do
      config = described_class.load('custom_config.yml')
      expect(config).to be_a(described_class)
    end
  end

  describe '#providers' do
    it 'returns empty hash when no providers configured' do
      config = described_class.new({})
      expect(config.providers).to eq({})
    end
  end
end
