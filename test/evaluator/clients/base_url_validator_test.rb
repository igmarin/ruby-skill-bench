# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    class BaseUrlValidatorTest < Minitest::Test
      Error = SkillBench::Clients::BaseUrlValidator::InvalidBaseURLError

      def test_accepts_https_non_loopback_with_credential
        url = 'https://api.example.com'

        assert_equal url, BaseUrlValidator.call(base_url: url, has_credential: true)
      end

      def test_accepts_http_loopback_hosts_with_credential
        %w[
          http://localhost:11434
          http://127.0.0.1:11434
          http://[::1]:11434
        ].each do |url|
          assert_equal url, BaseUrlValidator.call(base_url: url, has_credential: true),
                       "expected loopback URL to be accepted: #{url}"
        end
      end

      def test_rejects_http_non_loopback_with_credential
        error = assert_raises(Error) do
          BaseUrlValidator.call(base_url: 'http://evil.example.com', has_credential: true)
        end

        assert_match(/cleartext http/i, error.message)
        assert_match(/evil.example.com/, error.message)
      end

      def test_error_message_never_leaks_credential
        error = assert_raises(Error) do
          BaseUrlValidator.call(base_url: 'http://evil.example.com', has_credential: true)
        end

        # The validator is never given the secret, but assert defensively that the
        # message only describes the transport, not any credential material.
        refute_match(/bearer\s+\S/i, error.message)
      end

      def test_accepts_http_non_loopback_without_credential
        url = 'http://internal-proxy.example.com'

        assert_equal url, BaseUrlValidator.call(base_url: url, has_credential: false)
      end

      def test_opt_in_permits_http_non_loopback_with_credential
        url = 'http://internal-proxy.example.com'

        assert_equal url, BaseUrlValidator.call(base_url: url, has_credential: true, allow_insecure: true)
      end

      def test_rejects_relative_url
        ['/v1/chat/completions', 'api.example.com/v1'].each do |url|
          assert_raises(Error, "expected relative URL to be rejected: #{url}") do
            BaseUrlValidator.call(base_url: url, has_credential: true)
          end
        end
      end

      def test_rejects_garbage_and_non_http_schemes
        ['not a url', 'ftp://example.com', 'http://', 'https://'].each do |url|
          assert_raises(Error, "expected invalid URL to be rejected: #{url}") do
            BaseUrlValidator.call(base_url: url, has_credential: false)
          end
        end
      end

      def test_allows_blank_url_so_provider_can_supply_default
        assert_nil BaseUrlValidator.call(base_url: nil, has_credential: true)
        assert_equal '', BaseUrlValidator.call(base_url: '', has_credential: true)
      end
    end
  end
end
