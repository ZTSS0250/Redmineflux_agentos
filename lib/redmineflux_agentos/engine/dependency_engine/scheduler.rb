# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module DependencyEngine
      # DependencyEngine::Scheduler — subscribes to `agentos.issue_status_changed`
      # and re-queues any agent_run whose blocking_issue_id just cleared
      # (WORKFLOW.md §9/§13). Enqueues simultaneously-unblocked work in
      # `ai_tasks.priority` order (docs/PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md
      # §5). Checks the Pause/Resume scheduling gate atomically with every
      # queued -> running transition (§7, rao-013 Gate 2 finding #1) —
      # Phase 14 (rao-019) implements the body.
      module Scheduler
        def self.on_issue_closed(issue)
          raise NotImplementedError, 'Dependency-driven rescheduling is implemented in Phase 14 (rao-019)'
        end
      end
    end
  end
end
