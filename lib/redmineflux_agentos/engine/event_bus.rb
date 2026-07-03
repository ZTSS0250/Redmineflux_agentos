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
      @subscribed_events = []

      def self.publish(event_name, payload = {})
        ActiveSupport::Notifications.instrument("agentos.#{event_name}", payload)
      end

      def self.subscribe(event_name, &block)
        @subscribed_events << event_name.to_s
        ActiveSupport::Notifications.subscribe("agentos.#{event_name}", &block)
      end

      # rao-021: the health check ("Event Bus subscribers registered")
      # needs a way to confirm `config/initializers/redmineflux_agentos.rb`'s
      # `to_prepare` block actually ran and registered its subscribers —
      # `ActiveSupport::Notifications`' own subscriber list isn't a stable
      # public API to introspect, so this tracks it directly at the one
      # place a subscription can be created.
      def self.subscribed_events
        @subscribed_events.dup
      end
    end
  end
end
