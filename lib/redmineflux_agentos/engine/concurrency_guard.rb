# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    # RedminefluxAgentos::Engine::ConcurrencyGuard
    # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.9) — checked by
    # AgentEngine::Lifecycle before allowing `queued -> running`. Not
    # itemized as its own file in any ticket's Code Changes table, but
    # rao-019's own Objectives require it "with an atomic DB operation"
    # (rao-009's carried-forward requirement) — a genuine gap this ticket
    # must fill to make that Objective implementable at all.
    #
    # Atomicity: `.lock` (`SELECT ... FOR UPDATE`) on the rows actually
    # being counted, inside one transaction, so a concurrent caller
    # counting the same rows blocks until this transaction commits —
    # avoids the classic check-then-act race (count, then separately
    # update, with another caller's count reading stale data in between).
    # SQLite has no `FOR UPDATE` but already serializes writes at the
    # database level, so the same code is correct there too, just via a
    # different underlying mechanism.
    module ConcurrencyGuard
      DEFAULT_GLOBAL_CAP = 10
      DEFAULT_PROJECT_CAP = 3

      class << self
        # @param agent_run [RedminefluxAgentosAgentRun] must currently be
        #   `queued`
        # @return [Boolean] true if a slot was acquired and `agent_run` is
        #   now `running`; false if at either cap (agent_run left
        #   untouched, still `queued`) — being at capacity is normal
        #   backpressure, not an error (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
        #   §B.9: "the run stays queued... until a slot frees")
        def acquire(agent_run)
          acquired = false

          RedminefluxAgentosAgentRun.transaction do
            running = RedminefluxAgentosAgentRun.where(status: 'running').lock
            global_count = running.count
            project_count = running.where(project_id: agent_run.project_id).count

            if global_count < global_cap && project_count < project_cap(agent_run.project_id)
              agent_run.update!(status: 'running')
              acquired = true
            end
          end

          # `:start` (queued -> running) is special-cased in Lifecycle,
          # bypassing WorkflowEngine::StateMachine entirely — every other
          # transition publishes its own `agent_run.<status>` event via
          # the generic machine, but this one previously published
          # nothing at all, so `agent_run.running` (WORKFLOW.md §23,
          # "Agent Started") could never fire (rao-021 finding).
          RedminefluxAgentos::Engine::EventBus.publish('agent_run.running', record: agent_run) if acquired

          acquired
        end

        private

        def global_cap
          RedminefluxAgentos::Configuration::Store.get('global_concurrency_cap').to_i.nonzero? || DEFAULT_GLOBAL_CAP
        end

        def project_cap(project_id)
          project = Project.find_by(id: project_id)
          value = RedminefluxAgentos::Configuration::Store.get('project_concurrency_cap', project: project)
          value.to_i.nonzero? || DEFAULT_PROJECT_CAP
        end
      end
    end
  end
end
