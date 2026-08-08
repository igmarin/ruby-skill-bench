# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'open3'
require_relative '../constants'

module SkillBench
  module Execution
    # Manages isolated sandbox environments for running agent evaluations.
    # Handles copying files, initializing git, and capturing diffs.
    #
    # NOTE: A Docker build context is packaged under execution/docker so gem
    # installs can activate container isolation when a Docker daemon is present.
    # When `docker_available?` is false (no context, no daemon, or docker missing),
    # `container_id` stays nil and commands run on the host only if
    # `Config.allow_host_execution` is enabled (fail closed by default).
    class Sandbox
      attr_reader :path, :container_id

      # Global `git` options applied to every host-side invocation. They strip
      # the repository's and user's ability to launch external programs during
      # routine git operations on untrusted source:
      #   - core.attributesFile=/dev/null  no user-level .gitattributes drivers
      #   - core.fsmonitor=false           no fsmonitor hook program
      #   - core.hooksPath=/dev/null       no git hooks (pre-commit, etc.)
      #   - core.symlinks=false            symlinks treated as plain files
      # Combined with not copying the source `.git`, this neutralizes the
      # `.gitattributes`/config diff & filter driver code-execution vector.
      GIT_HARDENING = [
        '-c', 'core.attributesFile=/dev/null',
        '-c', 'core.fsmonitor=false',
        '-c', 'core.hooksPath=/dev/null',
        '-c', 'core.symlinks=false'
      ].freeze

      # Builds a hardened `git` argv: the binary, the hardening flags, then the
      # given subcommand and arguments. Single source of truth so every git
      # call in this file is invoked with the same protections.
      #
      # @param args [Array<String>] git subcommand and its arguments.
      # @return [Array<String>] full argv beginning with `git` and the flags.
      def self.git_command(*args)
        ['git', *GIT_HARDENING, *args]
      end

      # Absolute path to the packaged Docker build context.
      #
      # @return [String] path to lib/skill_bench/execution/docker
      def self.docker_context_path
        Constants::Sandbox.docker_context_path
      end

      # Versioned Docker image reference for this gem release.
      #
      # @return [String] image:tag such as evaluator-sandbox:1.2.0
      def self.image_ref
        Constants::Sandbox.image_ref
      end

      # Runs a block of code within a temporary, isolated sandbox directory.
      # The sandbox is initialized as a git repository and optionally wrapped in a Docker container.
      #
      # @param source_dir [String, Pathname] The directory to copy into the sandbox.
      # @yieldparam sandbox [SkillBench::Execution::Sandbox] The sandbox instance.
      # @return [Object] The result of the yielded block.
      # @raise [SystemCallError] when file operations or directory creation fails.
      # @raise [RuntimeError] when Docker commands fail.
      def self.run(source_dir, &)
        new(source_dir).run(&)
      end

      # @param source_dir [String, Pathname] The directory to copy into the sandbox.
      def initialize(source_dir)
        @source_dir = source_dir
        @path = nil
        @container_id = nil
      end

      # Executes the sandbox environment setup and yields the sandbox instance.
      #
      # @yieldparam sandbox [SkillBench::Execution::Sandbox] The sandbox instance.
      # @return [Object] The result of the yielded block.
      # @raise [SystemCallError] when file operations or directory creation fails.
      # @raise [RuntimeError] when Docker commands fail.
      def run
        Dir.mktmpdir('evaluator_sandbox_') do |sandbox_dir|
          @path = sandbox_dir
          copy_source_files(sandbox_dir)

          setup_git

          start_container if docker_available?
          begin
            yield self
          ensure
            stop_container
          end
        end
      end

      # Captures the git diff of changes made within the sandbox.
      #
      # @param sandbox_dir [String] The path to the sandbox directory.
      # @return [String] The git diff, or a message indicating no changes.
      # @raise [SystemCallError] when git commands fail.
      def self.capture_diff(sandbox_dir)
        sandbox_path = File.realpath(sandbox_dir)
        tmp_prefix = File.realpath(Dir.tmpdir) + File::SEPARATOR
        raise "Sandbox directory #{sandbox_dir} is outside temp directory" unless sandbox_path.start_with?(tmp_prefix)

        return 'No code changes made.' unless File.directory?(File.join(sandbox_path, '.git'))

        raise "Failed to stage changes in #{sandbox_path}" unless system(*git_command('add', '.'), chdir: sandbox_path)

        diff, status = Open3.capture2(*git_command('diff', '--cached'), chdir: sandbox_path)
        raise "Failed to capture diff in #{sandbox_path}" unless status.success?

        diff.strip.empty? ? 'No code changes made.' : diff
      end

      private

      # Initializes a fresh git repository in the sandbox and commits the
      # copied source as the baseline. All git calls are hardened so a
      # malicious source cannot trigger external programs (see GIT_HARDENING).
      #
      # @raise [RuntimeError] when any git command fails.
      def setup_git
        subcommands = [
          ['init', '--quiet'],
          ['config', 'user.email', 'evaluator@tessl.io'],
          ['config', 'user.name', 'Evaluator Sandbox'],
          ['add', '.'],
          ['commit', '--quiet', '-m', 'Initial commit']
        ]

        subcommands.each do |args|
          argv = self.class.git_command(*args)
          raise "Git command failed: #{argv.join(' ')}" unless system(*argv, chdir: @path)
        end
      end

      # Copies source files into the sandbox, including dotfiles, but never the
      # source's own `.git` directory (the sandbox creates its own fresh repo).
      # Validates symlinks to prevent path traversal.
      #
      # @param sandbox_dir [String] The destination sandbox directory.
      # @raise [RuntimeError] when a symlink points outside the source directory.
      def copy_source_files(sandbox_dir)
        source_real = File.realpath(@source_dir)
        copy_tree(@source_dir, sandbox_dir, source_real)
      end

      # Recursively copies entries from +src_dir+ into +dst_dir+. Any entry
      # named `.git` is skipped so a pre-existing repository (config diff/filter
      # drivers, hooks) from untrusted source never reaches host git operations.
      #
      # @param src_dir [String] The directory whose entries are copied.
      # @param dst_dir [String] The destination directory.
      # @param source_real [String] Real path of the copy root for symlink containment.
      # @raise [RuntimeError] when a symlink points outside the source directory.
      def copy_tree(src_dir, dst_dir, source_real)
        Dir.entries(src_dir).each do |entry|
          next if %w[. ..].include?(entry)
          next if entry == '.git'

          src = File.join(src_dir, entry)
          dst = File.join(dst_dir, entry)

          if File.symlink?(src)
            real = File.realpath(src)
            raise "Symlink #{entry} points outside source directory" unless real.start_with?("#{source_real}/")

            copy_item(real, dst, source_real)
          elsif File.directory?(src)
            copy_item(src, dst, source_real)
          else
            FileUtils.cp(src, dst)
          end
        end
      end

      def copy_item(src, dst, source_real)
        FileUtils.mkdir_p(dst)
        if File.directory?(src)
          copy_tree(src, dst, source_real)
        else
          FileUtils.cp(src, dst)
        end
      end

      # Checks if Docker is available and the sandbox Dockerfile context exists.
      #
      # @return [Boolean] true if Docker is available, false otherwise.
      def docker_available?
        docker_dir = self.class.docker_context_path
        return false unless File.directory?(docker_dir)
        return false unless File.file?(File.join(docker_dir, 'Dockerfile'))

        _stdout, _stderr, status = Open3.capture3('docker', 'info')
        status.success?
      rescue Errno::ENOENT
        false
      end

      # Starts a Docker container for isolated command execution.
      # Builds the image only when the versioned tag is not already present.
      # Uses hardened security settings for production safety.
      #
      # @raise [RuntimeError] when the Docker image cannot be built or the container fails to start.
      def start_container
        ensure_image
        image = self.class.image_ref

        # --user uid:gid: non-root
        # --security-opt no-new-privileges: no privilege escalation
        # --cap-drop ALL (+ CHOWN/DAC_OVERRIDE): minimal caps for git volume ops
        # --network none: no network during evals
        stdout, stderr, status = Open3.capture3(
          'docker', 'run', '-d', '--rm',
          '--user', "#{Process.uid}:#{Process.gid}",
          '--security-opt', 'no-new-privileges',
          '--cap-drop', 'ALL',
          '--cap-add', 'CHOWN',
          '--cap-add', 'DAC_OVERRIDE',
          '--network', 'none',
          '-v', "#{@path}:/sandbox:rw",
          image
        )

        raise "Failed to start Docker container: #{stderr}" unless status.success?

        @container_id = stdout.strip
      end

      # Ensures the versioned evaluator image exists locally, building only if missing.
      #
      # @raise [RuntimeError] when the image cannot be built.
      # @return [void]
      def ensure_image
        image = self.class.image_ref
        return if image_present?(image)

        docker_dir = self.class.docker_context_path
        latest = Constants::Sandbox.latest_image_ref
        built = system(
          'docker', 'build',
          '-t', image,
          '-t', latest,
          docker_dir,
          '--quiet'
        )
        raise "Failed to build Docker image #{image}" unless built
      end

      # @param image [String] full image reference including tag
      # @return [Boolean] true when docker already has the image
      def image_present?(image)
        _stdout, _stderr, status = Open3.capture3('docker', 'image', 'inspect', image)
        status.success?
      rescue Errno::ENOENT
        false
      end

      def stop_container
        return unless @container_id

        # Stop and remove the container (it's --rm so stopping also removes it)
        # We don't fail-fast on stop to avoid swallowing the original error if this is in an ensure block
        system('docker', 'stop', @container_id, out: File::NULL, err: File::NULL)
      end
    end
  end
end
