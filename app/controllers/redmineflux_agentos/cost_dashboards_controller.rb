# frozen_string_literal: true

module RedminefluxAgentos
  # Cost Dashboard (docs/UI-WIREFRAMES.md §6 — shown combined with Token
  # Usage in the original wireframe; routed separately per
  # docs/PHASE9-UI-UX-SPECIFICATION.md's page list). Data source:
  # `cost_trackings` directly (§6) — a budget-alert widget is visual
  # polish (out of scope); the underlying numbers it would alert on are
  # exposed here.
  class CostDashboardsController < BaseController
    def show
      @cost_trackings = RedminefluxAgentosCostTracking.where(project_id: @project.id).order(:period)
      @total_cost = @cost_trackings.sum(:total_cost)
    end
  end
end
