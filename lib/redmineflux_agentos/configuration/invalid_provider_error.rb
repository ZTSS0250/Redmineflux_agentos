# frozen_string_literal: true

module RedminefluxAgentos
  module Configuration
    # `active_provider` (Store, §12) resolved to a key nothing registered
    # into Provider::Registry — e.g. a typo, or a leftover reference to a
    # provider that was never wired up. `retryable: false`
    # (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §8.4) — a human must fix
    # the configuration; retrying an agent run against a broken config
    # wastes cycles without ever succeeding.
    class InvalidProviderError < RedminefluxAgentos::Error; end
  end
end
