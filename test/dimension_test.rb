# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class DimensionTest < Minitest::Test
    def test_initializes_with_name_description_and_max_score
      dimension = Dimension.new(name: 'correctness', description: 'Does it work?', max_score: 30)

      assert_equal 'correctness', dimension.name
      assert_equal 'Does it work?', dimension.description
      assert_equal 30, dimension.max_score
    end

    def test_initializes_with_nil_max_score
      dimension = Dimension.new(name: 'correctness', description: 'Does it work?', max_score: nil)

      assert_nil dimension.max_score
    end

    def test_default_dimensions_has_five_canonical_dimensions
      assert_equal 5, DEFAULT_DIMENSIONS.size

      names = DEFAULT_DIMENSIONS.map(&:name)
      expected_names = %w[correctness skill_adherence code_quality test_coverage documentation]

      assert_equal expected_names, names
    end

    def test_default_dimensions_have_descriptions
      DEFAULT_DIMENSIONS.each do |dimension|
        assert_predicate dimension.description.length, :positive?, "Expected #{dimension.name} to have a description"
      end
    end

    def test_default_dimensions_have_nil_max_score
      DEFAULT_DIMENSIONS.each do |dimension|
        assert_nil dimension.max_score
      end
    end

    def test_equality_with_same_attributes
      dim_a = Dimension.new(name: 'correctness', description: 'Does it work?', max_score: 30)
      dim_b = Dimension.new(name: 'correctness', description: 'Does it work?', max_score: 30)

      assert_equal dim_a, dim_b
      assert dim_a.eql?(dim_b)
    end

    def test_inequality_with_different_attributes
      dim_a = Dimension.new(name: 'correctness', description: 'Does it work?', max_score: 30)
      dim_b = Dimension.new(name: 'code_quality', description: 'Is it clean?', max_score: 20)

      refute_equal dim_a, dim_b
      refute dim_a.eql?(dim_b)
    end

    def test_hash_consistency_for_hash_keys
      dim_a = Dimension.new(name: 'correctness', description: 'Does it work?', max_score: 30)
      dim_b = Dimension.new(name: 'correctness', description: 'Does it work?', max_score: 30)

      assert_equal dim_a.hash, dim_b.hash
    end

    def test_can_be_used_as_hash_key
      dim = Dimension.new(name: 'correctness', description: 'Does it work?', max_score: 30)
      hash = { dim => 'value' }

      lookup = Dimension.new(name: 'correctness', description: 'Does it work?', max_score: 30)

      assert_equal 'value', hash[lookup]
    end
  end
end
