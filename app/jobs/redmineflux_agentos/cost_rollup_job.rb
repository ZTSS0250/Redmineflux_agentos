# frozen_string_literal: true

module RedminefluxAgentos
  # Daily cost_trackings aggregation from token_usages
  # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.1,
  # docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §10).
  #
  # `RATE_CARDS` values are illustrative, not real vendor pricing — §10 is
  # explicit that Cost Simulation is "real arithmetic on simulated
  # inputs... not a hardcoded $0.00", so a Cost Dashboard can be
  # meaningfully demonstrated; no design doc states exact numbers since
  # v1 has no real provider to price against.
  #
  # Aggregates by `(project_id, period)` only, matching
  # `docs/DATABASE-SCHEMA.md`'s actual unique index on `cost_trackings` —
  # not further split by provider/model, since v1 only ever has one
  # provider (`mock`) active at a time.
  class CostRollupJob < (defined?(ApplicationJob) ? ApplicationJob : ActiveJob::Base)
    queue_as :agentos_background
    retry_on StandardError, wait: ->(executions) { (executions**2) + 1 }, attempts: 3

    RATE_CARDS = {
      'mock-standard' => { prompt: 0.001, completion: 0.002 } # $ per 1K tokens
    }.freeze

    def perform(date = Date.yesterday)
      rate = rate_card
      usages = RedminefluxAgentosTokenUsage.where(created_at: date.all_day)

      usages.group_by(&:project_id).each do |project_id, rows|
        record = RedminefluxAgentosCostTracking.find_or_initialize_by(project_id: project_id, period: date)
        record.provider = rows.last.provider
        record.model = rows.last.model
        record.total_tokens = rows.sum(&:total_tokens)
        record.total_cost = rows.sum { |r| request_cost(r, rate) }.round(4)
        record.currency ||= 'USD'
        record.save!
      end
    end

    private

    def rate_card
      key = RedminefluxAgentos::Configuration::Store.get('cost_rules') || 'mock-standard'
      RATE_CARDS[key] || RATE_CARDS['mock-standard']
    end

    def request_cost(usage, rate)
      ((usage.prompt_tokens / 1000.0) * rate[:prompt]) + ((usage.completion_tokens / 1000.0) * rate[:completion])
    end
  end
end
