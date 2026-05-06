# frozen_string_literal: true

require "rspec"
require_relative "../../lib/agent_eval/commands/init"

RSpec.describe AgentEval::Commands::Init do
  describe ".run" do
    it "generates .agent-eval.yml by default" do
      described_class.run
      expect(File).to exist(".agent-eval.yml")
      config = YAML.safe_load(File.read(".agent-eval.yml"))
      expect(config).to have_key("providers")
    end

    it "generates Rails-specific config with --rails flag" do
      described_class.run(rails: true)
      config = YAML.safe_load(File.read(".agent-eval.yml"))
      expect(config).to have_key("rails")
    end
  end
end
