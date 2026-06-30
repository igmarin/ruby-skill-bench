# frozen_string_literal: true

require 'test_helper'
require 'skill_bench/rails/skill_templates'

module SkillBench
  module Rails
    class SkillTemplatesTest < Minitest::Test
      def test_service_object_generates_valid_ruby
        code = SkillTemplates.service_object('my_service')

        assert_includes code, 'class MyService'
        assert_includes code, 'def call'
        assert_includes code, 'frozen_string_literal'
        assert_includes code, 'rescue StandardError'
      end

      def test_service_object_with_hyphenated_name
        code = SkillTemplates.service_object('my-service')

        assert_includes code, 'class MyService'
      end

      def test_concern_generates_valid_ruby
        code = SkillTemplates.concern('auditable')

        assert_includes code, 'module Auditable'
        assert_includes code, 'extend ActiveSupport::Concern'
      end

      def test_active_record_model_generates_valid_ruby
        code = SkillTemplates.active_record_model('user_profile')

        assert_includes code, 'class UserProfile < ApplicationRecord'
        assert_includes code, 'validates :name, presence: true'
      end

      def test_camelize_snake_case
        assert_equal 'UserCreator', SkillTemplates.camelize('user_creator')
      end

      def test_camelize_kebab_case
        assert_equal 'OrderService', SkillTemplates.camelize('order-service')
      end

      def test_camelize_already_camel_case
        assert_equal 'UserCreator', SkillTemplates.camelize('UserCreator')
      end

      def test_camelize_mixed_separators
        assert_equal 'MyCoolSkill', SkillTemplates.camelize('my-cool_skill')
      end
    end
  end
end
