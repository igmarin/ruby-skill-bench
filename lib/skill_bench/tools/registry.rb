# frozen_string_literal: true

require_relative 'read_file'
require_relative 'write_file'
require_relative 'run_command'

module SkillBench
  module Tools
    # Registry for all available tools, providing their definitions to the LLM.
    class Registry
      # Recursively deep-freezes a tool-definition value (Hash/Array and contents)
      # so accidental mutation by a downstream consumer raises immediately.
      #
      # @param value [Object] The value to deep-freeze in place.
      # @return [Object] The same value, frozen along with everything it contains.
      def self.deep_freeze(value)
        children = case value
                   when Hash  then value.values
                   when Array then value
                   else []
                   end
        children.each { |child| deep_freeze(child) }
        value.freeze
      end
      private_class_method :deep_freeze

      # The static tool definitions sent to the LLM API. The tool schemas are
      # constant JSON-schema specs (no per-call state or runtime config), so the
      # array and its nested hashes are built once and deep-frozen for reuse
      # across every ReAct step instead of being reallocated on each call.
      #
      # @return [Array<Hash>] Frozen list of tools with their names, descriptions, and schemas.
      DEFINITIONS = deep_freeze(
        [
          ReadFile.definition,
          WriteFile.definition,
          RunCommand.definition
        ]
      )

      # Returns the memoized, frozen array of tool definitions for the LLM API.
      #
      # @return [Array<Hash>] The frozen list of available tools with their names, descriptions, and schemas.
      def self.definitions
        DEFINITIONS
      end
    end
  end
end
