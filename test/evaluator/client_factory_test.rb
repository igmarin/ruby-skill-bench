# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class ClientFactoryTest < Minitest::Test
    include Mocha::API # Include Mocha API for class method stubbing

    def setup
      Config.reset
      # Ensure providers are registered (in case they weren't loaded)
      SkillBench::Clients::ProviderRegistry.register(:openai, SkillBench::Clients::Providers::OpenAI)
      SkillBench::Clients::ProviderRegistry.register(:gemini, SkillBench::Clients::Providers::Gemini)
      SkillBench::Clients::ProviderRegistry.register(:ollama, SkillBench::Clients::Providers::Ollama)
    end

    def teardown
      Mocha::Mockery.instance.teardown # Clean up stubs after each test
    end

    def test_call_dispatches_to_openai_client_when_configured
      Config.current_llm_provider = :openai
      Config.setup do |config|
        config.set_provider_api_key(:openai, 'test_openai_key')
      end

      # Stub the OpenAI provider client class method
      SkillBench::Clients::Providers::OpenAI.stubs(:call).returns({ success: true, response: { message: { content: 'OpenAI response' } } })

      result = Client.call(system_prompt: 'System', messages: [{ role: 'user', content: 'Hi' }])

      assert result[:success]
      assert_equal 'OpenAI response', result[:response][:message][:content]
    end

    def test_call_dispatches_to_gemini_client_when_configured
      Config.current_llm_provider = :gemini
      Config.setup do |config|
        config.set_provider_api_key(:gemini, 'test_gemini_key')
        config.set_provider_project_id(:gemini, 'test-project')
        config.set_provider_location(:gemini, 'us-central1')
      end

      # Stub the Gemini provider client class method
      SkillBench::Clients::Providers::Gemini.stubs(:call).returns({ success: true, response: { message: { content: 'Gemini response' } } })

      result = Client.call(system_prompt: 'System', messages: [{ role: 'user', content: 'Hi' }])

      assert result[:success]
      assert_equal 'Gemini response', result[:response][:message][:content]
    end

    def test_call_dispatches_to_ollama_client_when_configured
      Config.current_llm_provider = :ollama
      Config.setup do |config|
        config.set_provider_model(:ollama, 'qwen2.5')
      end

      # Stub the Ollama provider client class method
      SkillBench::Clients::Providers::Ollama.stubs(:call).returns({ success: true, response: { message: { content: 'Ollama response' } } })

      result = Client.call(system_prompt: 'System', messages: [{ role: 'user', content: 'Hi' }])

      assert result[:success]
      assert_equal 'Ollama response', result[:response][:message][:content]
    end

    def test_call_dispatches_to_null_client_for_unsupported_provider
      Config.current_llm_provider = :unsupported_llm

      result = Client.call(system_prompt: 'System', messages: [{ role: 'user', content: 'Hi' }])

      refute result[:success]
      assert_match(/Unsupported or unconfigured LLM provider: 'unsupported_llm'/, result[:response][:error][:message])
    end

    def test_call_propagates_errors_from_provider_client
      Config.current_llm_provider = :openai
      Config.setup do |config|
        config.set_provider_api_key(:openai, 'test_openai_key')
      end

      # Stub the OpenAI provider client class method to return an error
      SkillBench::Clients::Providers::OpenAI.stubs(:call).returns({ success: false, response: { error: { message: 'Provider specific error' } } })

      result = Client.call(system_prompt: 'System', messages: [{ role: 'user', content: 'Hi' }])

      refute result[:success]
      assert_equal 'Provider specific error', result[:response][:error][:message]
    end

    def test_call_with_explicit_provider_overrides_config
      SkillBench::Clients::ProviderRegistry.register(:deepseek, SkillBench::Clients::Providers::DeepSeek)

      SkillBench::Clients::Providers::DeepSeek.stubs(:call).returns({ success: true, response: { message: { content: 'DeepSeek response' } } })

      result = Client.call(provider: :deepseek, system_prompt: 'System', messages: [{ role: 'user', content: 'Hi' }])

      assert result[:success]
      assert_equal 'DeepSeek response', result[:response][:message][:content]
    end

    def test_call_with_explicit_provider_ignores_config
      Config.current_llm_provider = :openai
      Config.setup do |config|
        config.set_provider_api_key(:openai, 'test_openai_key')
      end
      SkillBench::Clients::ProviderRegistry.register(:deepseek, SkillBench::Clients::Providers::DeepSeek)
      SkillBench::Clients::Providers::OpenAI.stubs(:call).returns({ success: true, response: { message: { content: 'openai' } } })
      SkillBench::Clients::Providers::DeepSeek.stubs(:call).returns({ success: true, response: { message: { content: 'deepseek' } } })

      result = Client.call(provider: :deepseek, system_prompt: 'System', messages: [{ role: 'user', content: 'Hi' }])

      assert_equal 'deepseek', result[:response][:message][:content]
    end

    def test_call_without_provider_preserves_backward_compat
      Config.current_llm_provider = :openai
      Config.setup do |config|
        config.set_provider_api_key(:openai, 'test_openai_key')
      end
      SkillBench::Clients::Providers::OpenAI.stubs(:call).returns({ success: true, response: { message: { content: 'OpenAI response' } } })

      result = Client.call(system_prompt: 'System', messages: [{ role: 'user', content: 'Hi' }])

      assert_equal 'OpenAI response', result[:response][:message][:content]
    end
  end
end
