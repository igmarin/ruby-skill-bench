# frozen_string_literal: true

require 'pathname'

module SkillBench
  module Task
    # Finds evaluation task directories under a root path.
    class DirectoryFinder
      # Finds the root task or all nested task directories in sorted order.
      #
      # @param root_path [Pathname] Directory to search.
      # @return [Array<Pathname>] Directories containing a task.md file.
      def self.call(root_path)
        return [root_path] if File.exist?(root_path.join('task.md'))

        Dir.glob(root_path.join('**/task.md')).map { |path| Pathname.new(path).parent }.uniq.sort
      end
    end
  end
end
