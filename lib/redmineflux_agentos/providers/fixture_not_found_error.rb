# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    # Raised only when the Fixture Selector finds no match *and* no
    # fallback fixture is configured at all (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md
    # §8.1) — an ordinary missing per-scenario fixture instead falls back to
    # the generic "unhandled scenario" fixture (§8.5) without raising.
    # `retryable: true` — a persistently failing retry surfaces as `dead`
    # on the Agent Dashboard for human investigation (§8.1).
    class FixtureNotFoundError < ProviderError; end
  end
end
