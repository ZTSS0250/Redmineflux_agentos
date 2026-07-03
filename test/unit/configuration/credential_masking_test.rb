# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

# rao-020 Gate 2 finding #1's mandatory test: a sensitive configuration
# key never renders its real value. This covers the LOGIC
# (`CredentialMasking.sensitive?`/`.display_value`) exhaustively — the
# other half of Gate 2's claim ("the rendered HTML source contains no
# plaintext secret") needs a real Rails view-rendering pass against the
# actual Settings template, which needs a live Redmine instance this
# environment doesn't have, same category of gap as every other phase.
class CredentialMaskingTest < ActiveSupport::TestCase
  def test_sensitive_key_patterns
    %w[credentials api_key ACCESS_TOKEN secret_key some_password provider_credential].each do |key|
      assert RedminefluxAgentos::Configuration::CredentialMasking.sensitive?(key), "#{key} should be sensitive"
    end
  end

  def test_ordinary_keys_are_not_sensitive
    %w[active_provider fixture_directory logging_level simulation_mode cost_rules token_rules].each do |key|
      refute RedminefluxAgentos::Configuration::CredentialMasking.sensitive?(key), "#{key} should not be sensitive"
    end
  end

  def test_sensitive_key_with_a_value_is_masked_not_shown
    result = RedminefluxAgentos::Configuration::CredentialMasking.display_value('api_key', 'sk-real-secret-value')

    assert_equal '•••• configured', result
    refute_includes result, 'sk-real-secret-value'
  end

  def test_sensitive_key_with_no_value_shows_not_configured
    result = RedminefluxAgentos::Configuration::CredentialMasking.display_value('api_key', nil)

    assert_equal 'Not configured', result
  end

  def test_non_sensitive_key_renders_its_real_value
    result = RedminefluxAgentos::Configuration::CredentialMasking.display_value('active_provider', 'mock')

    assert_equal 'mock', result
  end

  def test_masking_is_independent_of_value_shape
    # A sensitive value might be a Hash (e.g. a structured credential
    # blob), not just a String — masking must not assume a String and
    # accidentally leak structure via inspection/interpolation.
    result = RedminefluxAgentos::Configuration::CredentialMasking.display_value(
      'credentials', { 'client_id' => 'abc', 'client_secret' => 'super-secret' }
    )

    assert_equal '•••• configured', result
    refute_includes result, 'super-secret'
  end
end
