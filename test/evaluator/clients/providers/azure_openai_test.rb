# frozen_string_literal: true

require 'test_helper'
require_relative '../../../../lib/clients/providers/azure_openai'

class AzureOpenAITest < Minitest::Test
  def setup
    Evaluator::Config.reset
    @system_prompt = 'You are an assistant'
    @messages = [{ role: 'user', content: 'Hello' }]
  end

  def test_base_url_uses_configured_endpoint
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-key')
      config.set_provider_model(:azure, 'gpt-4')
      config.set_provider_endpoint(:azure, 'https://my-resource.openai.azure.com')
      config.current_llm_provider = :azure
    end

    client = create_client

    assert_equal 'https://my-resource.openai.azure.com', client.send(:endpoint)
    assert_equal "/openai/deployments/gpt-4/chat/completions?api-version=#{Evaluator::Clients::Providers::AzureOpenAI::DEFAULT_API_VERSION}", client.send(:request_path)
  end

  def test_request_path_includes_deployment
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-key')
      config.set_provider_model(:azure, 'gpt-4o')
      config.set_provider_endpoint(:azure, 'https://test.openai.azure.com')
      config.current_llm_provider = :azure
    end

    client = create_client

    assert_match(%r{/openai/deployments/gpt-4o/chat/completions}, client.send(:request_path))
  end

  def test_request_headers_include_api_key
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-api-key')
      config.set_provider_endpoint(:azure, 'https://test.openai.azure.com')
      config.current_llm_provider = :azure
    end

    client = create_client
    headers = client.send(:request_headers)

    assert_equal 'test-api-key', headers['api-key']
    refute headers.key?('Authorization')
  end

  def test_valid_config_with_all_settings
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-key')
      config.set_provider_endpoint(:azure, 'https://test.openai.azure.com')
      config.set_provider_model(:azure, 'gpt-4')
      config.current_llm_provider = :azure
    end

    client = create_client

    assert client.send(:valid_config?)
  end

  def test_valid_config_missing_api_key
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, nil)
      config.set_provider_endpoint(:azure, 'https://test.openai.azure.com')
      config.set_provider_model(:azure, 'gpt-4')
      config.current_llm_provider = :azure
    end

    client = create_client

    refute client.send(:valid_config?)
  end

  def test_valid_config_missing_endpoint
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-key')
      config.set_provider_endpoint(:azure, nil)
      config.set_provider_model(:azure, 'gpt-4')
      config.current_llm_provider = :azure
    end

    client = create_client

    refute client.send(:valid_config?)
  end

  def test_valid_config_missing_model
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-key')
      config.set_provider_endpoint(:azure, 'https://test.openai.azure.com')
      config.set_provider_model(:azure, nil)
      config.current_llm_provider = :azure
    end

    client = create_client

    refute client.send(:valid_config?)
  end

  def test_config_error_returns_structured_response
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, nil)
      config.set_provider_endpoint(:azure, nil)
      config.set_provider_model(:azure, nil)
      config.current_llm_provider = :azure
    end

    client = create_client
    result = client.send(:config_error)

    refute result[:success]
    assert_match(/AZURE_OPENAI_API_KEY/, result[:response][:error][:message])
    assert_match(/AZURE_OPENAI_ENDPOINT/, result[:response][:error][:message])
    assert_match(/AZURE_OPENAI_MODEL/, result[:response][:error][:message])
  end

  private

  def create_client
    Evaluator::Clients::Providers::AzureOpenAI.new(
      system_prompt: @system_prompt,
      messages: @messages
    )
  end
end
