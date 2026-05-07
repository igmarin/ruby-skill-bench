# frozen_string_literal: true

module Evaluator
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

      if defined?(Rails)
        Rails.logger.error(message)
        Rails.logger.error(backtrace)
      else
        warn(message)
        warn(backtrace)
      end
    end

    module_function :log_error
  end
end
