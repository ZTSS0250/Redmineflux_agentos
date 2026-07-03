# frozen_string_literal: true

module RedminefluxAgentos
  # Token Usage dashboard (docs/UI-WIREFRAMES.md §6). Data source:
  # `token_usages` directly (docs/PHASE9-UI-UX-SPECIFICATION.md §6) —
  # usage-by-agent bars / usage-by-day sparkline are the widgets;
  # charting itself is visual polish (rao-020 QA Test Plan, out of
  # scope) — the aggregated numbers those widgets would render from are
  # what this action exposes.
  class TokenUsagesController < BaseController
    def show
      scope = RedminefluxAgentosTokenUsage.where(project_id: @project.id)
      @total_tokens = scope.sum(:total_tokens)
      @by_agent = scope.joins(:agent_run).group('redmineflux_agentos_agent_runs.agent_id').sum(:total_tokens)
      @by_day = scope.group("date(created_at)").order("date(created_at)").sum(:total_tokens)
    end
  end
end
