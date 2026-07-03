# frozen_string_literal: true

module RedminefluxAgentos
  # Raised by DependencyEngine::Graph at insert time — no DB-level
  # constraint can express graph acyclicity, so this is the
  # application-level enforcement docs/DATABASE-SCHEMA.md already
  # documents as the design (Phase 2 §B.7).
  class DependencyCycleError < Error; end
end
