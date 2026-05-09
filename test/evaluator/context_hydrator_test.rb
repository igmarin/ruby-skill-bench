# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class ContextHydratorTest < Minitest::Test
    def test_call_returns_success_and_hydrated_context
      # Arrange
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'test.md'), 'Dummy skill content')

        # Act
        result = ContextHydrator.call(source_path: '.', base_path: Pathname.new(dir))

        # Assert
        assert result[:success]
        assert_match(/Dummy skill content/, result[:response][:context])
        assert_match(/<agent_context>/, result[:response][:context])
        assert_match(/<file path="test.md">/, result[:response][:context])
      end
    end

    def test_call_returns_error_on_failure
      # Act
      result = ContextHydrator.call(source_path: 'non_existent_path')

      # Assert
      refute result[:success]
      assert_match(/does not exist/, result[:response][:error][:message])
    end

    def test_loads_all_text_readable_extensions
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'readme.md'), 'Markdown content')
        File.write(File.join(dir, 'skill.rb'), 'class Skill; end')
        File.write(File.join(dir, 'config.json'), '{"key": "value"}')
        File.write(File.join(dir, 'settings.yml'), "foo: bar\n")
        File.write(File.join(dir, 'data.yaml'), "baz: qux\n")
        File.write(File.join(dir, 'notes.txt'), 'Plain text')
        File.write(File.join(dir, 'image.png'), 'binary') # should be skipped

        result = ContextHydrator.call(source_path: '.', base_path: Pathname.new(dir))

        assert result[:success]
        context = result[:response][:context]

        assert_match(/Markdown content/, context)
        assert_match(/class Skill; end/, context)
        assert_match(/config.json/, context)
        assert_match(/settings.yml/, context)
        assert_match(/data.yaml/, context)
        assert_match(/Plain text/, context)
        refute_match(/image.png/, context)
      end
    end

    def test_skips_files_over_fifty_kb
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'small.md'), 'small')
        File.write(File.join(dir, 'large.rb'), 'x' * 50_001)

        result = ContextHydrator.call(source_path: '.', base_path: Pathname.new(dir))

        assert result[:success]
        context = result[:response][:context]

        assert_match(/small/, context)
        refute_match(/large.rb/, context)
      end
    end
  end
end
