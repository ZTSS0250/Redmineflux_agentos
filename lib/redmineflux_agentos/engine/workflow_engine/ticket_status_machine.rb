# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module WorkflowEngine
      # The second of WorkflowEngine::StateMachine's two configured
      # instances (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.6,
      # WORKFLOW.md §14) — the ticket (issue) status workflow: Backlog ->
      # Ready -> InProgress -> CodeReview -> Testing -> Completed ->
      # Released. Configures `status_reader`/`status_writer` against
      # Redmine's own `Issue#status` (an `IssueStatus` association, not a
      # plain string column) so this really is the same engine class as
      # the agent-run machine, not a lookalike.
      #
      # Scope note: configured for completeness — rao-019's own Objective
      # requires "one class, two configured instances" — but nothing in
      # this ticket's scope drives an Issue through it yet.
      # `Mcp::Executor`'s `update_issue` tool (rao-018) already lets an
      # agent set any valid Redmine status directly per Redmine's own
      # tracker workflow rules; this engine does not attempt to re-derive
      # or override those rules, only offers an alternative, explicit
      # transition-table path for whichever future caller wants one.
      module TicketStatusMachine
        TRANSITIONS = [
          { from: :Backlog, to: :Ready, event: :become_ready },
          { from: :Ready, to: :InProgress, event: :start },
          { from: :InProgress, to: :CodeReview, event: :submit_for_review },
          { from: :CodeReview, to: :Testing, event: :approve_review },
          { from: :CodeReview, to: :InProgress, event: :request_changes },
          { from: :Testing, to: :Completed, event: :pass_qa },
          { from: :Testing, to: :InProgress, event: :fail_qa },
          { from: :Completed, to: :Released, event: :release }
        ].freeze

        STATUS_READER = ->(issue) { issue.status.name.to_sym }
        STATUS_WRITER = lambda { |issue, status|
          issue_status = IssueStatus.find_by(name: status.to_s)
          raise ArgumentError, "Unknown IssueStatus name: #{status}" unless issue_status

          issue.update!(status: issue_status)
        }

        # WORKFLOW.md §15 catalogs this as one flat event name
        # (`issue.status_changed`) regardless of which status was
        # entered — unlike the agent-run machine's one-event-per-status
        # convention (`agent_run.queued/.running/...`) — so this instance
        # overrides `event_name` rather than using the engine's default.
        MACHINE = RedminefluxAgentos::Engine::WorkflowEngine::StateMachine.new(
          transitions: TRANSITIONS, event_prefix: 'issue_status_changed',
          status_reader: STATUS_READER, status_writer: STATUS_WRITER,
          event_name: ->(_to) { 'issue.status_changed' }
        )

        def self.transition(issue, event)
          MACHINE.transition(issue, event)
        end
      end
    end
  end
end
