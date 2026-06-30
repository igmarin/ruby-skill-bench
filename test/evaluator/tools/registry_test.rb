# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Tools
    # Tests for the SkillBench::Tools::Registry
    class RegistryTest < Minitest::Test
      def test_definitions
        definitions = Registry.definitions

        assert_equal 3, definitions.length
        assert_equal 'read_file', definitions[0][:function][:name]
        assert_equal 'write_file', definitions[1][:function][:name]
        assert_equal 'run_command', definitions[2][:function][:name]
      end

      def test_definitions_returns_expected_static_schemas
        assert_equal(
          [ReadFile.definition, WriteFile.definition, RunCommand.definition],
          Registry.definitions
        )
      end

      def test_definitions_is_memoized_as_the_same_object
        first = Registry.definitions
        second = Registry.definitions

        assert_same first, second
      end

      def test_definitions_is_deep_frozen
        definitions = Registry.definitions

        assert_predicate definitions, :frozen?
        definitions.each do |tool|
          assert_predicate tool, :frozen?
          assert_predicate tool[:function], :frozen?
          assert_predicate tool[:function][:parameters], :frozen?
        end
      end
    end
  end
end
