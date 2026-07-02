# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    module Mock
      # The Mock AI Provider (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §1).
      # Deterministic, fixture-based, zero outbound network calls — this
      # invariant must be preserved by whatever Phase 12 (rao-017)
      # implements here and is verified by a dedicated test asserting no
      # network call is ever attempted (rao-017 Gate 2 finding #1).
      class MockProvider
        include RedminefluxAgentos::Providers::ProviderInterface

        def self.key
          :mock
        end
      end
    end
  end
end
