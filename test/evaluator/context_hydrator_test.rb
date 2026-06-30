# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class ContextHydratorTest < Minitest::Test
    def test_call_returns_success_and_hydrated_context
      # Arrange
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'test.md'), 'Dummy skill content')

        # Act
        result = Execution::ContextHydrator.call(source_path: '.', base_path: Pathname.new(dir))

        # Assert
        assert result[:success]
        assert_match(/Dummy skill content/, result[:response][:context])
        assert_match(/<agent_context>/, result[:response][:context])
        assert_match(/<file path="test.md">/, result[:response][:context])
      end
    end

    def test_call_returns_error_on_failure
      # Act
      result = Execution::ContextHydrator.call(source_path: 'non_existent_path')

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

        result = Execution::ContextHydrator.call(source_path: '.', base_path: Pathname.new(dir))

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

        result = Execution::ContextHydrator.call(source_path: '.', base_path: Pathname.new(dir))

        assert result[:success]
        context = result[:response][:context]

        assert_match(/small/, context)
        refute_match(/large.rb/, context)
      end
    end

    def test_rejects_sibling_directory_prefix_bypass
      Dir.mktmpdir do |parent|
        base = File.join(parent, 'foo')
        sibling = File.join(parent, 'foo-evil')
        FileUtils.mkdir_p(base)
        FileUtils.mkdir_p(sibling)
        File.write(File.join(sibling, 'secret.md'), 'SIBLING_SECRET_CONTENT')

        result = Execution::ContextHydrator.call(source_path: '../foo-evil', base_path: Pathname.new(base))

        refute result[:success]
        assert_match(/does not exist/, result[:response][:error][:message])
      end
    end

    def test_accepts_base_directory_itself
      Dir.mktmpdir do |parent|
        base = File.join(parent, 'foo')
        FileUtils.mkdir_p(base)
        File.write(File.join(base, 'base.md'), 'BASE_DIR_CONTENT')

        result = Execution::ContextHydrator.call(source_path: '.', base_path: Pathname.new(base))

        assert result[:success]
        assert_match(/BASE_DIR_CONTENT/, result[:response][:context])
      end
    end

    def test_accepts_legitimate_nested_subdirectory
      Dir.mktmpdir do |parent|
        base = File.join(parent, 'foo')
        nested = File.join(base, 'sub')
        FileUtils.mkdir_p(nested)
        File.write(File.join(nested, 'nested.md'), 'NESTED_SUBDIR_CONTENT')

        result = Execution::ContextHydrator.call(source_path: 'sub', base_path: Pathname.new(base))

        assert result[:success]
        assert_match(/NESTED_SUBDIR_CONTENT/, result[:response][:context])
      end
    end

    def test_rejects_symlinks
      secret_file = File.join(Dir.tmpdir, "skill_bench_test_secret_#{Process.pid}_#{Time.now.to_f}.txt")
      File.write(secret_file, 'SYMLINK_SECRET_CONTENT')

      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'real.md'), ' legitimate content')
        File.symlink(secret_file, File.join(dir, 'link.txt'))

        result = Execution::ContextHydrator.call(source_path: '.', base_path: Pathname.new(dir))

        assert result[:success]
        context = result[:response][:context]

        assert_match(/legitimate content/, context)
        refute_match(/SYMLINK_SECRET_CONTENT/, context)
      end
    ensure
      FileUtils.rm_f(secret_file)
    end

    def test_enforces_total_size_cap
      Dir.mktmpdir do |dir|
        # Each file is under MAX_FILE_SIZE (50_000) but together they exceed
        # MAX_TOTAL_CONTEXT_SIZE (1_000_000), so hydration must fail.
        21.times { |i| File.write(File.join(dir, "chunk_#{i}.md"), 'x' * 49_000) }

        result = Execution::ContextHydrator.call(source_path: '.', base_path: Pathname.new(dir))

        refute result[:success]
        assert_match(/does not exist/, result[:response][:error][:message])
      end
    end

    def test_included_files_are_read_and_stat_at_most_once
      Dir.mktmpdir do |dir|
        files = {
          File.join(dir, 'alpha.md') => 'alpha content',
          File.join(dir, 'beta.rb') => 'class Beta; end'
        }
        files.each { |path, body| File.write(path, body) }

        read_counts = Hash.new(0)
        size_counts = Hash.new(0)
        tracked = files.keys
        File.singleton_class.prepend(io_spy(tracked, read_counts, size_counts))

        result = Execution::ContextHydrator.call(source_path: '.', base_path: Pathname.new(dir))

        assert result[:success]
        files.each_key do |path|
          assert_equal 1, read_counts[path], "expected #{path} to be read exactly once"
          assert_operator size_counts[path], :<=, 1, "expected #{path} to be stat-ed at most once"
        end
      end
    end

    private

    # Builds a module that, when prepended onto File's singleton class, counts how
    # often the tracked paths are passed to File.read / File.size while delegating
    # to the real implementations so behavior is preserved.
    def io_spy(tracked, read_counts, size_counts)
      Module.new do
        define_method(:read) do |*args, &block|
          read_counts[args.first] += 1 if tracked.include?(args.first)
          super(*args, &block)
        end

        define_method(:size) do |*args, &block|
          size_counts[args.first] += 1 if tracked.include?(args.first)
          super(*args, &block)
        end
      end
    end
  end
end
