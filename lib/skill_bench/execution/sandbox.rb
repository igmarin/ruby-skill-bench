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
    # NOTE: Container isolation is not yet shipped. No Docker build context is
    # packaged, so `docker_available?` always returns false and `start_container`
    # is never reached — `container_id` stays nil and commands run on the host
    # (gated by the allowlist and `Config.allow_host_execution`). The container
    # code below is the planned isolation model, retained but currently inactive.
    class Sandbox
      attr_reader :path, :container_id

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

        raise "Failed to stage changes in #{sandbox_path}" unless system('git', 'add', '.', chdir: sandbox_path)

        diff, status = Open3.capture2('git', 'diff', '--cached', chdir: sandbox_path)
        raise "Failed to capture diff in #{sandbox_path}" unless status.success?

        diff.strip.empty? ? 'No code changes made.' : diff
      end

      private

      def setup_git
        cmds = [
          ['git', 'init', '--quiet'],
          ['git', 'config', 'user.email', 'evaluator@tessl.io'],
          ['git', 'config', 'user.name', 'Evaluator Sandbox'],
          ['git', 'add', '.'],
          ['git', 'commit', '--quiet', '-m', 'Initial commit']
        ]

        cmds.each do |argv|
          raise "Git command failed: #{argv.join(' ')}" unless system(*argv, chdir: @path)
        end
      end

      # Copies source files into the sandbox, including dotfiles.
      # Validates symlinks to prevent path traversal.
      #
      # @param sandbox_dir [String] The destination sandbox directory.
      # @raise [RuntimeError] when a symlink points outside the source directory.
      def copy_source_files(sandbox_dir)
        source_real = File.realpath(@source_dir)
        copy_tree(@source_dir, sandbox_dir, source_real)
      end

      def copy_tree(src_dir, dst_dir, source_real)
        Dir.entries(src_dir).each do |entry|
          next if %w[. ..].include?(entry)

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

      # Checks if Docker is available and the sandbox Dockerfile exists.
      #
      # @return [Boolean] true if Docker is available, false otherwise.
      def docker_available?
        docker_dir = File.expand_path('docker', __dir__)
        return false unless File.directory?(docker_dir)

        _stdout, _stderr, status = Open3.capture3('docker', 'info')
        status.success?
      rescue Errno::ENOENT
        false
      end

      # Starts a Docker container for isolated command execution.
      # Builds the image only if it does not already exist.
      # Uses hardened security settings for production safety.
      #
      # @raise [RuntimeError] when the Docker image cannot be built or the container fails to start.
      def start_container
        image_name = Constants::Sandbox::DOCKER_IMAGE_NAME
        docker_dir = File.expand_path('docker', __dir__)

        # Build image (Docker layer cache handles no-op builds)
        raise "Failed to build Docker image #{image_name}" unless system('docker', 'build', '-t', image_name, docker_dir, '--quiet')

        # Start a detached container with hardened security settings
        # --user $(id -u):$(id -g): Runs as non-root user
        # --security-opt no-new-privileges: Prevents privilege escalation
        # --cap-drop ALL: Drops all Linux capabilities
        # --cap-add CHOWN, DAC_OVERRIDE: Adds back minimal capabilities for git operations
        # --network none: Disables network access for additional isolation
        stdout, stderr, status = Open3.capture3(
          'docker', 'run', '-d', '--rm',
          '--user', "#{Process.uid}:#{Process.gid}",
          '--security-opt', 'no-new-privileges',
          '--cap-drop', 'ALL',
          '--cap-add', 'CHOWN',
          '--cap-add', 'DAC_OVERRIDE',
          '--network', 'none',
          '-v', "#{@path}:/sandbox:rw",
          image_name
        )

        raise "Failed to start Docker container: #{stderr}" unless status.success?

        @container_id = stdout.strip
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
