# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/agent_eval/models/provider'

RSpec.describe AgentEval::Models::Provider do
  describe '#initialize' do
    it 'accepts name, runtime, and llm' do
      provider = described_class.new(name: 'openai', runtime: 'opencode', llm: 'openai')
      expect(provider.name).to eq('openai')
      expect(provider.runtime).to eq('opencode')
      expect(provider.llm).to eq('openai')
    end
  end

  describe '#config' do
    it 'returns merged config from YAML and env vars' do
      provider = described_class.new(name: 'openai', runtime: 'opencode', llm: 'openai', config: { api_key: 'key' })
      expect(provider.config[:api_key]).to eq('key')
    end

    it 'merges env var with config when both present' do
      env_key = 'AGENT_EVAL_OPENAI_API_KEY'
      old_value = ENV.fetch(env_key, nil)
      ENV[env_key] = 'env_key_value'
      provider = described_class.new(name: 'openai', runtime: 'opencode', llm: 'openai', config: { api_key: 'config_key' })
      merged = provider.merged_config
      expect(merged[:api_key]).to eq('env_key_value')
      ENV[env_key] = old_value if old_value
    end

    it 'uses config when env var not set' do
      provider = described_class.new(name: 'openai', runtime: 'opencode', llm: 'openai', config: { api_key: 'config_key' })
      merged = provider.merged_config
      expect(merged[:api_key]).to eq('config_key')
    end
  end
end
