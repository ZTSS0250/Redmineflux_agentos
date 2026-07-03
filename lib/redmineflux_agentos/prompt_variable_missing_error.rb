# frozen_string_literal: true

module RedminefluxAgentos
  # A required `{{variable}}` was absent at resolve time — either from a
  # Prompt Template (Phase 2 §A.10) or, per rao-017 §8.2, from a Mock
  # Provider fixture's own interpolation. `retryable: false` — a human must
  # fix the template/fixture or the caller's variables; retrying cannot
  # succeed (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §8.2).
  class PromptVariableMissingError < Error; end
end
