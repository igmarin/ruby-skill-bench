# frozen_string_literal: true

require 'test_helper'
require_relative '../../../../lib/clients/providers/ollama'

class OllamaProviderTest < Minitest::Test
  def test_config_error_returns_message
    provider = Evaluator::Clients::Providers::Ollama.new(system_prompt: 'test', messages: [])
    # Force @model to nil to simulate missing configuration regardless of ~/.evaluator.json
    provider.instance_variable_set(:@model, nil)

    error = provider.send(:config_error)

    refute error[:success]
    assert_equal 'OLLAMA_MODEL not set for Ollama', error.dig(:response, :error, :message)
  end

  def test_base_url_uses_env_when_set
    ENV['OLLAMA_BASE_URL'] = 'http://custom:11434'
    provider = Evaluator::Clients::Providers::Ollama.new(system_prompt: 'test', messages: [])

    assert_equal 'http://custom:11434', provider.send(:base_url)
  ensure
    ENV.delete('OLLAMA_BASE_URL')
  end

  def test_base_url_defaults_to_localhost
    Evaluator::Config.reset

    provider = Evaluator::Clients::Providers::Ollama.new(system_prompt: 'test', messages: [])

    assert_equal 'http://localhost:11434', provider.send(:base_url)
  end

  def test_base_url_uses_config_when_set
    config_url = 'http://configured-host:11434'
    Evaluator::Config.setup do |config|
      config.set_provider_base_url(:ollama, config_url)
    end

    provider = Evaluator::Clients::Providers::Ollama.new(
      system_prompt: 'test',
      messages: [],
      model: 'qwen2.5'
    )

    assert_equal config_url, provider.send(:base_url)
  ensure
    Evaluator::Config.reset
  end

  def test_base_url_falls_back_to_localhost_when_not_set
    Evaluator::Config.reset

    provider = Evaluator::Clients::Providers::Ollama.new(
      system_prompt: 'test',
      messages: [],
      model: 'qwen2.5'
    )

    assert_equal 'http://localhost:11434', provider.send(:base_url)
  end

  def test_valid_config_with_model
    provider = Evaluator::Clients::Providers::Ollama.new(
      system_prompt: 'test',
      messages: [],
      model: 'qwen2.5'
    )

    assert provider.send(:valid_config?)
  end

  def test_valid_config_with_empty_model
    provider = Evaluator::Clients::Providers::Ollama.new(
      system_prompt: 'test',
      messages: [],
      model: ''
    )

    refute provider.send(:valid_config?)
  end

  def test_request_headers_with_api_key
    provider = Evaluator::Clients::Providers::Ollama.new(
      system_prompt: 'test',
      messages: [],
      api_key: 'test-key'
    )

    headers = provider.send(:request_headers)

    assert_equal 'application/json', headers['Content-Type']
    assert_equal 'Bearer test-key', headers['Authorization']
  end

  def test_request_headers_without_api_key
    provider = Evaluator::Clients::Providers::Ollama.new(
      system_prompt: 'test',
      messages: [],
      api_key: ''
    )

    headers = provider.send(:request_headers)

    assert_equal 'application/json', headers['Content-Type']
    refute headers.key?('Authorization')
  end

  def test_request_path
    provider = Evaluator::Clients::Providers::Ollama.new(system_prompt: 'test', messages: [])

    assert_equal '/v1/chat/completions', provider.send(:request_path)
  end
end
