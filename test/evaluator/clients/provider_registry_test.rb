# frozen_string_literal: true

require 'test_helper'
require_relative '../../../lib/clients/provider_registry'
require_relative '../../../lib/clients/providers/null_client'

class ProviderRegistryTest < Minitest::Test
  def setup
    # Save original registry state
    @original_providers = Evaluator::Clients::ProviderRegistry.instance_variable_get(:@providers).dup
    # Clear the registry for test isolation
    Evaluator::Clients::ProviderRegistry.instance_variable_set(:@providers, {})
  end

  def teardown
    # Restore original registry state
    Evaluator::Clients::ProviderRegistry.instance_variable_set(:@providers, @original_providers)
  end

  def test_register_and_for
    # Create a dummy class
    dummy_class = Class.new

    Evaluator::Clients::ProviderRegistry.register(:test_provider, dummy_class)

    assert_equal dummy_class, Evaluator::Clients::ProviderRegistry.for(:test_provider)
  end

  def test_for_returns_null_client_for_unknown_provider
    result = Evaluator::Clients::ProviderRegistry.for(:nonexistent)

    assert_equal Evaluator::Clients::Providers::NullClient, result
  end

  def test_providers_returns_hash
    result = Evaluator::Clients::ProviderRegistry.providers

    assert_instance_of Hash, result
  end

  def test_multiple_providers
    class1 = Class.new
    class2 = Class.new

    Evaluator::Clients::ProviderRegistry.register(:provider1, class1)
    Evaluator::Clients::ProviderRegistry.register(:provider2, class2)

    assert_equal class1, Evaluator::Clients::ProviderRegistry.for(:provider1)
    assert_equal class2, Evaluator::Clients::ProviderRegistry.for(:provider2)
  end
end
