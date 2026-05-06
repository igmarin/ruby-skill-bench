# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/agent_eval/models/skill'

RSpec.describe AgentEval::Models::Skill do
  describe '.discover' do
    it 'discovers skills from the default skills/ directory' do
      skills = described_class.discover
      expect(skills).to be_an(Array)
      expect(skills).not_to be_empty
      expect(skills.first).to be_a(described_class)
    end

    it 'discovers skills from a custom path' do
      skills = described_class.discover('custom_skills/')
      expect(skills).to be_an(Array)
    end
  end

  describe '#initialize' do
    it 'accepts a name and path' do
      skill = described_class.new(name: 'test-skill', path: 'skills/test-skill')
      expect(skill.name).to eq('test-skill')
      expect(skill.path).to eq('skills/test-skill')
    end
  end
end
