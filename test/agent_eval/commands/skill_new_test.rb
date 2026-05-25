# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Commands
    class SkillNewTest < Minitest::Test
      def setup
        @original_dir = Dir.pwd
        @tmp_dir = Dir.mktmpdir('skill_new_test')
        Dir.chdir(@tmp_dir)
        FileUtils.mkdir('skills')
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_run_creates_simple_skill
        SkillNew.run(name: 'my-skill', mode: 'simple')

        assert_path_exists 'skills/my-skill/SKILL.md'
        content = File.read('skills/my-skill/SKILL.md')

        assert_includes content, '# Skill: my-skill'
      end

      def test_run_creates_advanced_skill
        SkillNew.run(name: 'my_skill', mode: 'advanced')

        assert_path_exists 'skills/my_skill/skill.rb'
        content = File.read('skills/my_skill/skill.rb')

        assert_includes content, 'class MySkill'
      end

      def test_run_creates_rails_skill_with_service_object
        SkillNew.run(name: 'my-skill', mode: 'rails', template: 'service_object')

        assert_path_exists 'skills/my-skill/service.rb'
        content = File.read('skills/my-skill/service.rb')

        assert_includes content, 'class MySkill'
      end

      def test_run_creates_rails_skill_with_concern
        SkillNew.run(name: 'my_skill', mode: 'rails', template: 'concern')

        assert_path_exists 'skills/my_skill/concern.rb'
        content = File.read('skills/my_skill/concern.rb')

        assert_includes content, 'module MySkill'
      end

      def test_run_creates_rails_skill_with_active_record_model
        SkillNew.run(name: 'my_skill', mode: 'rails', template: 'active_record_model')

        assert_path_exists 'skills/my_skill/model.rb'
        content = File.read('skills/my_skill/model.rb')

        assert_includes content, 'class MySkill < ApplicationRecord'
      end

      def test_run_raises_on_invalid_mode
        assert_raises(ArgumentError) do
          SkillNew.run(name: 'my-skill', mode: 'invalid')
        end
      end

      def test_simple_skill_template
        template = SkillNew.simple_skill_template('test-skill')

        assert_includes template, '# Skill: test-skill'
        assert_includes template, '## Description'
        assert_includes template, '## Context'
        assert_includes template, '## Workflow'
      end

      def test_advanced_skill_template
        template = SkillNew.advanced_skill_template('snake_case_skill')

        assert_includes template, 'class SnakeCaseSkill'
        assert_includes template, 'frozen_string_literal'
        assert_includes template, 'def call'
      end

      def test_camelize
        assert_equal 'MySkill', SkillNew.camelize('my_skill')
        assert_equal 'MySkill', SkillNew.camelize('my skill')
      end
    end
  end
end
