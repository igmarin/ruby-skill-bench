# frozen_string_literal: true

require "rspec"
require_relative "../../lib/agent_eval/models/provider"

RSpec.describe AgentEval::Models::Provider do
  describe "#initialize" do
    it "accepts name, runtime, and llm" do
      provider = described_class.new(name: "openai", runtime: "opencode", llm: "openai")
      expect(provider.name).to eq("openai")
      expect(provider.runtime).to eq("opencode")
      expect(provider.llm).to eq("openai")
    end
  end

  describe "#config" do
    it "returns merged config from YAML and env vars" do
      provider = described_class.new(name: "openai", runtime: "opencode", llm: "openai", config: { api_key: "key" })
      expect(provider.config[:api_key]).to eq("key")
    end
  end
end
