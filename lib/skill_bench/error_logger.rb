# frozen_string_literal: true

module SkillBench
  # Shared error logging mixin for service objects.
  # Logs error message and backtrace to Rails.logger or stderr.
  module ErrorLogger
    # Logs an error with message and backtrace.
    #
    # @param error [StandardError] The exception to log
    # @param prefix [String] Optional prefix for the log message
    # @return [void]
    def log_error(error, prefix = nil)
      message = prefix ? "#{prefix}: #{error.message}" : error.message
      backtrace = error.backtrace&.first(5)&.join("\n") || '(no backtrace)'

      return if skip_stderr_output?

      if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
        Rails.logger.error(message)
        Rails.logger.error(backtrace)
      else
        warn(message)
        warn(backtrace)
      end
    end

    # @return [Boolean] true when stderr should be skipped (test mode without explicit capture).
    def skip_stderr_output?
      defined?(Minitest) && !$stderr.is_a?(StringIO)
    end

    module_function :log_error
    module_function :skip_stderr_output?
  end
end
