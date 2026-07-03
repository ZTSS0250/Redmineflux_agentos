# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module WorkflowEngine
      # WorkflowEngine::StateMachine — one generic, declarative
      # transition-table engine, configured (not subclassed) for both the
      # agent-run state machine (WORKFLOW.md §8) and the ticket-status
      # workflow (WORKFLOW.md §14) — deliberately not two hand-rolled
      # implementations (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.6).
      # Every successful transition publishes an event on EventBus.
      #
      # `status_reader`/`status_writer` default to a plain `status` string
      # column (agent_runs' shape) but are overridable — the ticket-status
      # instance configures these against Redmine's own `Issue#status`
      # (an `IssueStatus` association, not a plain column) so one engine
      # genuinely serves both machines rather than assuming AgentOS owns
      # the status column being transitioned.
      #
      # Scope note: the `queued -> running` transition for agent_runs is
      # NOT driven through this generic engine — see
      # `AgentEngine::Lifecycle`'s comment for why that one transition's
      # guard-and-mutate must be atomic in a way this engine's separate
      # check-then-act shape can't express without a real risk of
      # reintroducing the exact race the Concurrency Guard exists to
      # prevent.
      class StateMachine
        DEFAULT_STATUS_READER = ->(record) { record.status.to_sym }
        DEFAULT_STATUS_WRITER = ->(record, status) { record.update!(status: status.to_s) }

        # @param transitions [Array<Hash>] each `{from:, to:, event:,
        #   guard: ->(record) { true/false } }` — `guard` optional
        # @param event_prefix [String] e.g. "agent_run" — used by the
        #   default `event_name` proc: published events are
        #   `"agentos.{event_prefix}.{to}"` (matches WORKFLOW.md §15's
        #   `agent_run.queued/.running/...` cataloging — one event name
        #   per target status)
        # @param event_name [Proc, nil] override for state machines whose
        #   documented event shape isn't "one name per target status" —
        #   e.g. the ticket-status instance publishes a single flat
        #   `issue.status_changed` name regardless of `to` (WORKFLOW.md
        #   §15), so it overrides this instead of using the default
        def initialize(transitions:, event_prefix:, status_reader: DEFAULT_STATUS_READER,
                       status_writer: DEFAULT_STATUS_WRITER, event_name: nil)
          @transitions = transitions
          @event_prefix = event_prefix
          @status_reader = status_reader
          @status_writer = status_writer
          @event_name = event_name || ->(to) { "#{event_prefix}.#{to}" }
        end

        # @return [Boolean] true if the transition fired, false if a guard
        #   rejected it (record left untouched) — a rejected guard is
        #   normal backpressure, not an error (matches
        #   docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.9's framing for
        #   the concurrency case, generalized to every guarded transition)
        # @raise [ArgumentError] if no transition table entry matches the
        #   record's current status + event at all — that is a genuine
        #   programming error (an event that was never a valid transition
        #   for this state), not backpressure
        def transition(record, event)
          current = @status_reader.call(record)
          event = event.to_sym
          match = @transitions.find { |t| t[:from] == current && t[:event] == event }
          raise ArgumentError, "No transition for event :#{event} from status :#{current}" unless match

          return false if match[:guard] && !match[:guard].call(record)

          @status_writer.call(record, match[:to])
          RedminefluxAgentos::Engine::EventBus.publish(@event_name.call(match[:to]), record: record, from: current,
                                                                                      to: match[:to])
          true
        end
      end
    end
  end
end
