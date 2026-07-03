# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module DependencyEngine
      # DependencyEngine::Scheduler — re-queues any agent_run whose
      # `blocking_issue_id` just closed (WORKFLOW.md §9/§13), in
      # `ai_tasks`-linked-issue priority order, `created_at` as tiebreaker
      # (docs/PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md §5). Owns the
      # Pause/Resume scheduling gate (§7) — checked by
      # `AgentEngine::Lifecycle` before every `queued -> running`
      # transition attempt.
      #
      # Scope note: `on_issue_closed` only re-queues *existing*
      # `waiting_on_dep` runs — it does not create brand-new `agent_run`
      # rows for a newly-eligible `ai_task` that never had one. §7's other
      # pause-gate case ("creating a new agent_run for the project") has
      # no concrete call site yet in this ticket's scope — nothing here
      # proactively creates runs; that's a ticket-generation/scheduling
      # concern no file in rao-019's Code Changes table owns.
      module Scheduler
        PAUSE_KEY = 'execution_paused'

        class << self
          # @param issue [Issue] the Redmine issue that just closed
          def on_issue_closed(issue)
            blocked = RedminefluxAgentosAgentRun.where(status: 'waiting_on_dep', blocking_issue_id: issue.id).to_a
            return if blocked.empty?

            priority_ordered(blocked).each do |run|
              RedminefluxAgentos::Engine::AgentEngine::Lifecycle.transition(run, :clear)
            end
          end

          # @return [Boolean] true if the project's execution is paused
          #   (docs/PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md §7) — a
          #   `redmineflux_agentos_configurations` row, not a new
          #   `agent_runs` state, per that section's explicit decision
          def paused?(project_id)
            project = Project.find_by(id: project_id)
            value = RedminefluxAgentos::Configuration::Store.get(PAUSE_KEY, project: project)
            value.is_a?(Hash) && value['paused'] == true
          end

          private

          # Highest Redmine issue priority first (`IssuePriority#position`,
          # ascending severity by Redmine convention — sorted descending
          # here so the most severe goes first), then `created_at` as the
          # documented tiebreaker.
          def priority_ordered(runs)
            runs.sort_by { |run| [-(run.issue&.priority&.position || 0), run.created_at] }
          end
        end
      end
    end
  end
end
