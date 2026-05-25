# frozen_string_literal: true

module SkillBench
  module Services
    # Parses variant specifications for skill comparison.
    class VariantParser
      # Parses a variant specification string.
      #
      # @param spec [String] Variant spec (e.g., "pack:rails" or "/path/to/skill")
      # @return [Hash] Parsed variant with :type (:pack or :path) and corresponding key
      def self.call(spec)
        new(spec).call
      end

      # @param spec [String] Variant spec (e.g., "pack:rails" or "/path/to/skill")
      def initialize(spec)
        @spec = spec
      end

      # Parses the variant specification.
      #
      # @return [Hash] Parsed variant with :type (:pack or :path) and corresponding key
      def call
        if @spec.start_with?('pack:')
          { type: :pack, name: @spec.sub('pack:', '') }
        else
          { type: :path, path: @spec }
        end
      end
    end
  end
end
