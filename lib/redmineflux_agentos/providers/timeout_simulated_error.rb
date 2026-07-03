# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    # A deliberate, test-mode-only condition (`simulation_mode:
    # timeout_simulation`, docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §8.3,
    # §12) for exercising the Agent Engine's retry/backoff behavior without
    # waiting on a real slow API — never triggered in normal
    # (`deterministic`) operation. `retryable: true`.
    class TimeoutSimulatedError < ProviderError; end
  end
end
