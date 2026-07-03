# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    # Base class for every Provider Interface call failure
    # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.7's `ProviderError`).
    # Mock-Provider-specific subclasses live alongside this file
    # (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §8).
    class ProviderError < RedminefluxAgentos::Error; end
  end
end
