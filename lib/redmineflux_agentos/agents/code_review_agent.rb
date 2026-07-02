# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #15 — RESERVED. Out of scope until code-writing agents
    # ship (v3, docs/PRODUCT-ROADMAP.md); no prompt category or event
    # bindings exist for this role (docs/PHASE6-AGENT-ARCHITECTURE.md §1).
    # AgentEngine::Registry (Phase 14) must explicitly reject scheduling
    # this key rather than silently no-op (rao-011 Gate 3 finding #1) —
    # not enforced here since this class has no `call` override to guard.
    class CodeReviewAgent < BaseAgent
      def self.key
        :code_review
      end
    end
  end
end
