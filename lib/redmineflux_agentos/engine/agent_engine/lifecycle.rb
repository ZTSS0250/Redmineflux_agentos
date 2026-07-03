# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module AgentEngine
      # AgentEngine::Lifecycle — owns the agent_runs.status state machine
      # exactly as specified in WORKFLOW.md §8
      # (queued/running/waiting_on_dep/completed/failed/dead/cancelled).
      # Delegates every transition except `:start` to
      # `WorkflowEngine::StateMachine` (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
      # §A.6).
      #
      # `:start` (queued -> running) is special-cased rather than routed
      # through the generic engine: its guard (the Concurrency Guard's cap
      # check) and its mutation (flipping status to running) must happen
      # as ONE atomic operation, or a second caller could pass the same
      # guard check before the first caller's mutation commits — exactly
      # the check-then-act race `ConcurrencyGuard.acquire` exists to
      # prevent (rao-007/rao-009's carried-forward requirement). The
      # generic engine's guard-then-separately-write shape can't express
      # that atomicity, so `ConcurrencyGuard.acquire` performs both steps
      # itself for this one transition.
      module Lifecycle
        TRANSITIONS = [
          { from: :running, to: :waiting_on_dep, event: :block },
          { from: :waiting_on_dep, to: :queued, event: :clear },
          { from: :running, to: :completed, event: :complete },
          { from: :running, to: :failed, event: :fail },
          { from: :failed, to: :queued, event: :retry, guard: ->(r) { r.attempts < r.max_attempts } },
          { from: :failed, to: :dead, event: :exhaust, guard: ->(r) { r.attempts >= r.max_attempts } },
          { from: :queued, to: :cancelled, event: :cancel },
          { from: :running, to: :cancelled, event: :cancel },
          { from: :waiting_on_dep, to: :cancelled, event: :cancel }
        ].freeze

        MACHINE = RedminefluxAgentos::Engine::WorkflowEngine::StateMachine.new(
          transitions: TRANSITIONS, event_prefix: 'agent_run'
        )

        class << self
          # @return [Boolean] see WorkflowEngine::StateMachine#transition
          #   and ConcurrencyGuard.acquire's return-value contracts — both
          #   use false for "not now, try later," never an exception
          def transition(agent_run, event)
            if event.to_sym == :start
              return false if RedminefluxAgentos::Engine::DependencyEngine::Scheduler.paused?(agent_run.project_id)
              # `agent_run.agent` is a required association in real data
              # (the model's `belongs_to :agent` has no `optional: true`)
              # — nil here means test/fixture data that never set one, not
              # a real-world case this guard needs to police; only a
              # genuinely-disabled agent blocks the transition.
              return false if agent_run.agent && !Registry.enabled?(agent_run.agent)

              return RedminefluxAgentos::Engine::ConcurrencyGuard.acquire(agent_run)
            end

            MACHINE.transition(agent_run, event)
          end

          # Increments `attempts`, transitions to `failed`, then
          # immediately decides `retry` (back to `queued`) or `exhaust`
          # (`dead`) based on the updated count — one call for the Runner
          # to make on any unhandled error, instead of it needing to know
          # the retry-vs-exhaust decision itself (WORKFLOW.md §8).
          def record_failure!(agent_run, error_message: nil)
            agent_run.update!(error_message: error_message) if error_message
            agent_run.increment!(:attempts)
            transition(agent_run, :fail)
            transition(agent_run, agent_run.attempts < agent_run.max_attempts ? :retry : :exhaust)
          end
        end
      end
    end
  end
end
