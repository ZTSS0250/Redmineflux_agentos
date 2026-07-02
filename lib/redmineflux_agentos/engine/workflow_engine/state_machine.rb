# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module WorkflowEngine
      # WorkflowEngine::StateMachine — one generic, declarative
      # transition-table engine, configured (not subclassed) for both the
      # agent-run state machine (WORKFLOW.md §8) and the ticket-status
      # workflow (WORKFLOW.md §14) — deliberately not two hand-rolled
      # implementations (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.6).
      # Every successful transition publishes an event on EventBus. Phase 14
      # (rao-019) implements the body.
      class StateMachine
        def initialize(transitions:)
          @transitions = transitions
        end

        def transition(record, event)
          raise NotImplementedError, 'Transition execution is implemented in Phase 14 (rao-019)'
        end
      end
    end
  end
end
