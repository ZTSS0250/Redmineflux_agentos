# frozen_string_literal: true

module RedminefluxAgentos
  # Malformed `{{variable}}` syntax in a template or fixture — a syntax
  # defect, not a missing-value defect (see PromptVariableMissingError).
  # `retryable: false` (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §8.2).
  class PromptTemplateInvalidError < Error; end
end
