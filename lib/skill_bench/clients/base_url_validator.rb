# frozen_string_literal: true

require 'uri'

module SkillBench
  module Clients
    # Validates a provider `base_url` before it is used to build an HTTP
    # connection that may carry an API key / bearer token.
    #
    # Security rationale: `base_url` is taken verbatim from config/env input and
    # the authenticated request attaches a credential to whatever host it names.
    # Left unchecked this is an SSRF surface, and an `http://` URL would transmit
    # the credential in cleartext. This service enforces:
    #
    # - the URL must be an absolute `http`/`https` URL with a host (empty/relative
    #   /garbage values are rejected);
    # - when a credential will be attached, non-loopback hosts MUST use `https`;
    #   loopback hosts (`localhost`, `127.0.0.1`, `::1`) MAY use `http` — the
    #   legitimate self-hosted/Ollama case — and an explicit opt-in
    #   (`allow_insecure_base_url`) can permit cleartext for non-loopback hosts.
    #
    # A blank (`nil`/empty) `base_url` is allowed so providers may supply their
    # own (https) default downstream. Error messages describe only the transport
    # and never include the credential.
    class BaseUrlValidator
      # Hosts permitted to use cleartext `http` even with a credential attached.
      LOOPBACK_HOSTS = %w[localhost 127.0.0.1 ::1].freeze

      # Raised when a base URL is structurally invalid or would leak a credential
      # over cleartext transport. The message never contains the credential.
      class InvalidBaseURLError < StandardError; end

      # Validates a base URL and returns it unchanged when valid.
      #
      # @param base_url [String, nil] the URL to validate; blank values are
      #   returned as-is so a provider default can be applied later.
      # @param has_credential [Boolean] whether a credential (api key/bearer
      #   token) will be attached to requests sent to this URL.
      # @param allow_insecure [Boolean] explicit opt-in that permits cleartext
      #   `http` to a non-loopback host even when a credential is attached.
      # @raise [InvalidBaseURLError] when the URL is invalid or insecure.
      # @return [String, nil] the validated URL (blank input returned unchanged).
      def self.call(base_url:, has_credential: false, allow_insecure: false)
        new(base_url, has_credential, allow_insecure).call
      end

      # @param base_url [String, nil] the URL to validate.
      # @param has_credential [Boolean] whether a credential will be attached.
      # @param allow_insecure [Boolean] opt-in permitting cleartext non-loopback.
      def initialize(base_url, has_credential, allow_insecure)
        @base_url = base_url
        @has_credential = has_credential
        @allow_insecure = allow_insecure
      end

      # Runs the validation.
      #
      # @raise [InvalidBaseURLError] when the URL is invalid or insecure.
      # @return [String, nil] the validated URL.
      def call
        return @base_url if blank?(@base_url)

        validate_absolute_http_url!
        validate_secure_transport!
        @base_url
      end

      private

      def blank?(value)
        value.to_s.strip.empty?
      end

      def uri
        @uri ||= URI.parse(@base_url.to_s)
      rescue URI::InvalidURIError
        nil
      end

      def validate_absolute_http_url!
        return if uri.is_a?(URI::HTTP) && !blank?(uri.hostname)

        raise InvalidBaseURLError,
              "Invalid provider base_url #{@base_url.inspect}: " \
              'must be an absolute http(s) URL with a host.'
      end

      def validate_secure_transport!
        return unless @has_credential
        return if uri.scheme == 'https'
        return if loopback?
        return if @allow_insecure

        raise InvalidBaseURLError,
              'Insecure provider base_url: refusing to send a credential over cleartext http ' \
              "to non-loopback host #{uri.hostname.inspect}. Use https, target a loopback host, " \
              'or set allow_insecure_base_url: true to override.'
      end

      def loopback?
        LOOPBACK_HOSTS.include?(uri.hostname)
      end
    end
  end
end
