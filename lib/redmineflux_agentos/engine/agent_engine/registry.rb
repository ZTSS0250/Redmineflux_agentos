# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module AgentEngine
      # AgentEngine::Registry — maps an agent key to its class,
      # tool_allowlist, and enabled/disabled flag
      # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.5). Open/Closed
      # extension point: a new agent role is a new `register` call, never a
      # Runner change. MUST reject scheduling the reserved `:code_review`
      # key until explicitly activated (rao-011 Gate 3 finding #1) — Phase 14
      # (rao-019) implements the body.
      #
      # rao-021 (Phase 16 §B.3/Gate 1 finding): `enabled?` closes a real
      # enforcement gap found during the Phase 16 RBAC/config audit — no
      # code anywhere read `RedminefluxAgentosAgent#status` before this;
      # a disabled agent's queued runs would have executed anyway.
      # `Lifecycle.transition(:start)` now calls this before acquiring a
      # concurrency slot, the same "not now" contract `Scheduler.paused?`
      # already uses on the line above it. The `Rails.cache` read here is
      # what Phase 2 §B.3 means by "Agent registry ... invalidated on
      # config_json updated (enable/disable...)" — this is the hot-path
      # read that requirement exists to make cheap. NOTE: the only writer
      # of `RedminefluxAgentosAgent#status`, `Admin::AgentsController#update`,
      # is still the Phase 10 (rao-015) skeleton stub (`head :no_content`,
      # no persistence at all) — building that controller's real CRUD was
      # never a deliverable of any ticket through rao-020 and is out of
      # scope for rao-021 too (not one of its named carried-forward
      # requirements). `invalidate!` is exposed here, ready for that
      # controller's eventual real `update` action to call — logged as a
      # Gate 1 finding in rao-021 rather than silently absorbed as scope
      # creep on an already-HIGH-complexity ticket.
      module Registry
        RESERVED_KEYS = %i[code_review].freeze

        @agents = {}

        class << self
          def register(agent_class)
            @agents[agent_class.key] = agent_class
          end

          def for(agent_key)
            raise ArgumentError, "#{agent_key} is reserved and not yet active" if RESERVED_KEYS.include?(agent_key.to_sym)

            @agents[agent_key.to_sym] or raise ArgumentError, "Unknown agent key: #{agent_key}"
          end

          # rao-021: lets the health check confirm the boot-time
          # `to_prepare` block's agent registration actually ran, without
          # needing to know any specific agent key.
          def registered_keys
            @agents.keys
          end

          # @param agent_record [RedminefluxAgentosAgent]
          # @return [Boolean] false for a disabled agent — checked before
          #   every `queued -> running` transition (Lifecycle)
          def enabled?(agent_record)
            Rails.cache.fetch(cache_key(agent_record.id)) { agent_record.status == 'enabled' }
          end

          # Explicit invalidation (docs/PHASE1-SPECIFICATION.md §1.3 NFR) —
          # call after any write to `RedminefluxAgentosAgent#status` or
          # `#config_json`.
          def invalidate!(agent_record)
            Rails.cache.delete(cache_key(agent_record.id))
          end

          private

          def cache_key(agent_id)
            "redmineflux_agentos/agent_enabled/#{agent_id}"
          end
        end
      end
    end
  end
end
