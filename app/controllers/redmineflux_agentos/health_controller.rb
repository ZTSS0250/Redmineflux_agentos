# frozen_string_literal: true

module RedminefluxAgentos
  # Boot-state health check (rao-021, Phase 16 Objectives). Deliberately
  # NOT behind `require_login`/`accept_api_auth` (unlike every other
  # AgentOS controller, CLAUDE.md's blanket rule) — a load balancer,
  # uptime monitor, or orchestration liveness/readiness probe cannot
  # authenticate as a Redmine user, and a health endpoint that requires a
  # session is unusable for its actual purpose. The response body stays
  # minimal (status + boolean checks only, no internal state, no
  # sensitive data) precisely because it's reachable without auth.
  #
  # The three checks map 1:1 to the three things
  # `config/initializers/redmineflux_agentos.rb`'s `to_prepare` block
  # does at boot (provider registration, agent registration, Event Bus
  # subscription) — each one failing to have happened is a real,
  # distinct boot failure mode, not a single generic "up/down" flag
  # (rao-021 Test Case #4: an unregistered Mock Provider must report
  # unhealthy, never a false positive).
  class HealthController < ApplicationController
    def show
      checks = {
        agent_registry_populated: RedminefluxAgentos::Engine::AgentEngine::Registry.registered_keys.any?,
        provider_registry_populated: RedminefluxAgentos::Providers::Registry.registered?(:mock),
        event_bus_subscribed: RedminefluxAgentos::Engine::EventBus.subscribed_events.any?
      }
      healthy = checks.values.all?

      render json: { status: healthy ? 'healthy' : 'unhealthy', checks: checks },
             status: healthy ? :ok : :service_unavailable
    end

    # Ops-facing aggregate metrics (rao-021 Objectives: "agent run
    # throughput, token/cost trends, dependency-graph depth — surfaced
    # for ops, not just the product dashboards"). Same no-auth posture as
    # `show` and for the same reason — a metrics scraper can't
    # authenticate as a Redmine user either. Every figure here is a
    # cross-project aggregate (count/sum/group), never a per-project or
    # per-user breakdown, so this stays safe to expose without the
    # per-project permission checks the real dashboards enforce
    # (docs/PHASE9-UI-UX-SPECIFICATION.md — Token Usage/Cost dashboards
    # are gated per-project precisely because their figures are
    # project-identifiable; these totals are not).
    #
    # "dependency-graph depth" is approximated as edge/project counts,
    # not a true max-depth graph traversal — an exact depth computation
    # across every project's graph on every metrics poll would be an
    # unbounded per-request cost (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
    # §B.9's no-unbounded-query ethos), which no design doc's Objective
    # wording requires literally.
    def metrics
      render json: {
        agent_run_throughput: RedminefluxAgentosAgentRun.group(:status).count,
        cost_trend_last_7_days: RedminefluxAgentosCostTracking.where(period: 6.days.ago.to_date..Date.current)
                                                               .group(:period).sum(:total_cost),
        token_trend_last_7_days: RedminefluxAgentosCostTracking.where(period: 6.days.ago.to_date..Date.current)
                                                                .group(:period).sum(:total_tokens),
        dependency_graph: {
          total_edges: RedminefluxAgentosDependency.count,
          projects_with_dependencies: RedminefluxAgentosDependency.joins(:ai_task)
                                                                    .distinct
                                                                    .count('redmineflux_agentos_ai_tasks.project_id')
        }
      }
    end
  end
end
