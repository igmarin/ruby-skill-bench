# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/agent_eval/models/provider_registry'

RSpec.describe AgentEval::Models::ProviderRegistry do
  describe '.load_from_config' do
    it 'loads providers from config hash' do
      config = { 'providers' => { 'openai' => { 'runtime' => 'opencode', 'llm' => 'openai' } } }
      registry = described_class.load_from_config(config)
      expect(registry.providers['openai']).to be_a(AgentEval::Models::Provider)
    end
  end

  describe '#get' do
    it 'returns provider by name' do
      provider = AgentEval::Models::Provider.new(name: 'test', runtime: 'r', llm: 'l')
      registry = described_class.new(providers: { 'test' => provider })
      expect(registry.get('test')).to eq(provider)
    end
  end
end
