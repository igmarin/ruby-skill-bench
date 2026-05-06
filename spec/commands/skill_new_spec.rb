# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/agent_eval/commands/skill_new'

RSpec.describe AgentEval::Commands::SkillNew do
  describe '.run' do
    around(:each) do |example|
      Dir.mktmpdir do |tmp_dir|
        Dir.chdir(tmp_dir) do
          example.run
        end
      end
    end

    it 'creates a simple skill with SKILL.md' do
      described_class.run(name: 'test-skill', mode: 'simple')
      expect(File).to exist('skills/test-skill/SKILL.md')
    end

    it 'creates an advanced skill with Ruby class' do
      described_class.run(name: 'test-skill-adv', mode: 'advanced')
      expect(File).to exist('skills/test-skill-adv/skill.rb')
    end
  end
end
