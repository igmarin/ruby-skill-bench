# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Clients
    class RequestBuilderTest < Minitest::Test
      def test_build_connection_returns_faraday_connection
        conn = RequestBuilder.build_connection('https://api.example.com')

        assert_instance_of Faraday::Connection, conn
        assert_equal 'https://api.example.com', conn.url_prefix.to_s.chomp('/')
      end

      def test_execute_makes_post_request
        stub_request(:post, 'https://api.example.com/v1/chat')
          .with(
            headers: { 'Content-Type' => 'application/json' },
            body: { model: 'test-model' }.to_json
          )
          .to_return(status: 200, body: { choices: [] }.to_json)

        conn = RequestBuilder.build_connection('https://api.example.com')
        response = RequestBuilder.execute(
          conn,
          '/v1/chat',
          headers: { 'Content-Type' => 'application/json' },
          body: { model: 'test-model' }
        )

        assert_equal 200, response.status
      end
    end
  end
end
