# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

# rao-017 Test Case #4 / rao-008 Gate 3 finding #1: a misconfigured
# fixture_directory is a loud boot-time warning, never a silent
# per-request failure.
class FixtureLoaderTest < ActiveSupport::TestCase
  def test_validate_directory_warns_when_missing
    RedminefluxAgentos::Configuration::Store.stubs(:get).with('fixture_directory').returns('does/not/exist')
    Rails.logger.expects(:warn).with(regexp_matches(/fixture_directory does not exist/))

    refute RedminefluxAgentos::Providers::Mock::FixtureLoader.validate_directory!
  end

  def test_validate_directory_passes_for_the_real_directory
    assert RedminefluxAgentos::Providers::Mock::FixtureLoader.validate_directory!
  end
end
