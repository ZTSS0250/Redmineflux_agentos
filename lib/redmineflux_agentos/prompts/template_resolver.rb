# frozen_string_literal: true

module RedminefluxAgentos
  module Prompts
    # PromptManager::TemplateResolver (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
    # §A.10) — resolves the single `is_active: true` template row for a key,
    # validates required variables before ever reaching the Provider, and
    # composes the final prompt via `{{variable}}` interpolation
    # (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §6). Cached with explicit
    # invalidation on template activation (Phase 2 §B.3). Implemented in
    # Phase 14 (rao-019).
    module TemplateResolver
      def self.resolve(key, agent: nil, variables: {})
        raise NotImplementedError, 'Prompt template resolution is implemented in Phase 14 (rao-019)'
      end
    end
  end
end
