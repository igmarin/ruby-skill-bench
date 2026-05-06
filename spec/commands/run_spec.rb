# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/agent_eval/commands/run'

RSpec.describe AgentEval::Commands::Run do
  describe '.run' do
    it 'executes an eval with a skill and provider' do
      # Mock dependencies
      eval = instance_double(AgentEval::Models::Eval, name: 'test-eval')
      skill = instance_double(AgentEval::Models::Skill, name: 'test-skill')
      provider = instance_double(AgentEval::Models::Provider, name: 'openai')
      config = instance_double(AgentEval::Models::Config, providers: { 'openai' => {} })
      registry = instance_double(AgentEval::Models::ProviderRegistry)

      expect(AgentEval::Models::Config).to receive(:load).and_return(config)
      expect(AgentEval::Models::ProviderRegistry).to receive(:load_from_config).with(config.providers).and_return(registry)
      expect(registry).to receive(:get).with('openai').and_return(provider)
      expect(AgentEval::Models::Eval).to receive(:load).with('evals/test-eval').and_return(eval)
      expect(AgentEval::Models::Skill).to receive(:discover).and_return([skill])
      expect(AgentEval::Commands::Run).to receive(:spawn_agent).with(eval, skill, provider).and_return('result')
      expect(AgentEval::Commands::Run).to receive(:score_result).with(eval, 'result').and_return({ pass: true })

      described_class.run(eval_name: 'test-eval', skill_name: 'test-skill', provider_name: 'openai')
    end
  end
end
