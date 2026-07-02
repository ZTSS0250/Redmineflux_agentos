# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    # RedminefluxAgentos::Engine::EventBus — a thin wrapper over
    # ActiveSupport::Notifications, namespaced under `agentos.*`
    # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.7). Synchronous,
    # in-process by design — subscribers MUST be fast/non-blocking
    # (enqueue a job for real work); this is a mandatory implementation
    # requirement, not advisory (rao-007 Gate 2 finding #1). The event
    # catalog is WORKFLOW.md §15 — not duplicated here.
    module EventBus
      def self.publish(event_name, payload = {})
        ActiveSupport::Notifications.instrument("agentos.#{event_name}", payload)
      end

      def self.subscribe(event_name, &block)
        ActiveSupport::Notifications.subscribe("agentos.#{event_name}", &block)
      end
    end
  end
end
