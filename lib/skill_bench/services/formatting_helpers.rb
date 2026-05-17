# frozen_string_literal: true

module SkillBench
  module Services
    # Shared string-formatting utilities used across output formatters.
    module FormattingHelpers
      module_function

      # Converts a snake_case name to Title Case.
      #
      # @param name [String, Symbol] The dimension name.
      # @return [String] Human-readable name.
      def humanize(name)
        name.to_s.split('_').map(&:capitalize).join(' ')
      end

      # Formats a numeric delta with a +/- sign.
      #
      # @param delta [Numeric] The delta value.
      # @return [String] Formatted delta string.
      def delta_str(delta)
        delta >= 0 ? "+#{delta}" : delta.to_s
      end

      # Truncates a string to a maximum length with ellipsis.
      #
      # @param text [String] The text to truncate.
      # @param max_length [Integer] Maximum length.
      # @return [String] Truncated text.
      def truncate(text, max_length)
        return text if text.length <= max_length

        "#{text[0...max_length]}..."
      end

      # Returns the Unicode arrow icon for a trend direction.
      #
      # @param direction [Symbol] :improved, :regressed, or :unchanged.
      # @return [String] Arrow icon.
      def trend_icon(direction)
        { improved: '↑', regressed: '↓', unchanged: '→' }.fetch(direction, '?')
      end
    end
  end
end
