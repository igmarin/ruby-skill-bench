# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

module SkillBench
  module Services
    class TemplateRegistryTest < Minitest::Test
      def test_call_resolves_task_md_template_for_crud_category
        result = TemplateRegistry.call(:task_md, :crud)

        assert_kind_of String, result
        refute_empty result
      end

      def test_call_resolves_criteria_json_template_for_api_category
        result = TemplateRegistry.call(:criteria_json, :api)

        assert_kind_of String, result
        refute_empty result
      end

      def test_call_resolves_skill_md_template_for_background_job_category
        result = TemplateRegistry.call(:skill_md, :background_job)

        assert_kind_of String, result
        refute_empty result
      end

      def test_call_supports_all_valid_categories
        categories = %i[
          crud api background_job controller model
          migration concern policy form_object view_component
        ]

        categories.each do |category|
          result = TemplateRegistry.call(:task_md, category)

          assert_kind_of String, result, "Expected String for category #{category}"
          refute_empty result, "Expected non-empty template for category #{category}"
        end
      end

      def test_call_supports_all_valid_template_types
        types = %i[task_md criteria_json skill_md]

        types.each do |template_type|
          result = TemplateRegistry.call(template_type, :crud)

          assert_kind_of String, result, "Expected String for type #{template_type}"
          refute_empty result, "Expected non-empty template for type #{template_type}"
        end
      end

      def test_call_interpolates_variables
        result = TemplateRegistry.call(:task_md, :crud, { skill_name: 'UserCreator' })

        assert_includes result, 'UserCreator'
        refute_includes result, '{{skill_name}}'
      end

      def test_call_interpolates_multiple_variables
        result = TemplateRegistry.call(:task_md, :crud, { skill_name: 'OrderService', category: 'crud' })

        assert_includes result, 'OrderService'
        assert_includes result, 'crud'
      end

      def test_call_leaves_unmatched_placeholders_intact
        result = TemplateRegistry.call(:task_md, :crud, {})

        assert_includes result, '{{'
      end

      def test_call_returns_template_without_variables
        result = TemplateRegistry.call(:task_md, :crud)

        assert_kind_of String, result
        refute_empty result
      end

      def test_call_raises_for_invalid_category
        assert_raises(ArgumentError) do
          TemplateRegistry.call(:task_md, :invalid_category)
        end
      end

      def test_call_raises_for_invalid_template_type
        assert_raises(ArgumentError) do
          TemplateRegistry.call(:invalid_type, :crud)
        end
      end

      def test_call_raises_with_descriptive_message_for_invalid_category
        error = assert_raises(ArgumentError) do
          TemplateRegistry.call(:task_md, :nonexistent)
        end

        assert_match(/invalid category/i, error.message)
        assert_includes error.message, 'nonexistent'
      end

      def test_call_raises_with_descriptive_message_for_invalid_type
        error = assert_raises(ArgumentError) do
          TemplateRegistry.call(:nonexistent, :crud)
        end

        assert_match(/invalid template type/i, error.message)
        assert_includes error.message, 'nonexistent'
      end

      def test_call_accepts_string_keys_for_template_type_and_category
        result = TemplateRegistry.call('task_md', 'crud')

        assert_kind_of String, result
        refute_empty result
      end

      def test_call_accepts_string_keys_for_variables
        result = TemplateRegistry.call(:task_md, :crud, { 'skill_name' => 'MyService' })

        assert_includes result, 'MyService'
      end

      def test_task_md_template_contains_expected_structure
        result = TemplateRegistry.call(:task_md, :crud)

        assert_includes result, '# Task'
      end

      def test_criteria_json_template_is_valid_json
        result = TemplateRegistry.call(:criteria_json, :crud)

        parsed = JSON.parse(result)

        assert_kind_of Hash, parsed
      end

      def test_criteria_json_round_trips_through_criteria_loader_for_every_category
        TemplateRegistry::CATEGORIES.each do |category|
          json = TemplateRegistry.call(:criteria_json, category)

          Dir.mktmpdir do |dir|
            path = File.join(dir, 'criteria.json')
            File.write(path, json)

            result = SkillBench::Criteria.call(path: path)

            assert result[:success], "Criteria for #{category} failed to load: #{result.dig(:response, :error, :message)}"

            dimensions = result[:response][:criteria].dimensions
            total = dimensions.sum(&:max_score)

            assert_equal 100, total, "max_score sum for #{category} should be 100, got #{total}"
          end
        end
      end

      def test_skill_md_template_contains_expected_structure
        result = TemplateRegistry.call(:skill_md, :crud)

        assert_includes result, '# Skill'
      end
    end
  end
end
