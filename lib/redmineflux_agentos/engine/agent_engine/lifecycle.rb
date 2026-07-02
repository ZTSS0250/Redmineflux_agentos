# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module AgentEngine
      # AgentEngine::Lifecycle — owns the agent_runs.status state machine
      # exactly as specified in WORKFLOW.md §8
      # (queued/running/waiting_on_dep/completed/failed/dead/cancelled).
      # Delegates every transition to WorkflowEngine::StateMachine so
      # agent-run and ticket-status transitions share one implementation
      # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.6). Phase 14
      # (rao-019) implements the body.
      module Lifecycle
        def self.transition(agent_run, event)
          raise NotImplementedError, 'Agent run state transitions are implemented in Phase 14 (rao-019)'
        end
      end
    end
  end
end
