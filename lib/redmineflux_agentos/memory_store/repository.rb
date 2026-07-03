# frozen_string_literal: true

module RedminefluxAgentos
  module MemoryStore
    # MemoryStore::Repository (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
    # §A.9) — a thin, leaf-level (no dependencies on other AgentOS
    # modules) data access class over `redmineflux_agentos_agent_memories`.
    # Not itemized as its own file in any ticket's Code Changes table, but
    # `AgentEngine::Runner`'s own sequence diagram (Phase 2 §A.5) calls
    # `Mem.fetch`/`Mem.write` directly — a genuine gap this ticket fills,
    # scoped exactly to the three methods §A.9 already specifies.
    module Repository
      class << self
        # @param agent [RedminefluxAgentosAgent]
        # @param project [Project, nil] — nil fetches cross-project
        #   (shared) memory, per §A.9's "no separate code path" rule
        # @param scope [String, Symbol] `long_term` or `short_term`
        # @return [Array<Hash>] `{key:, value:}` for every non-expired row
        def fetch(agent, project, scope: 'long_term')
          records = RedminefluxAgentosAgentMemory
                    .where(agent_id: agent.id, project_id: project&.id, scope: scope.to_s)
                    .where('expires_at IS NULL OR expires_at > ?', Time.now)

          records.map { |r| { key: r.key, value: parse(r.value_json) } }
        end

        # Upserts on the `(agent_id, project_id, scope, key)` unique index
        # (docs/DATABASE-SCHEMA.md).
        # @param expires_at [Time, nil] required in practice for
        #   `scope: 'short_term'` — §A.9's sweep only ever targets rows
        #   that have one; a short_term row with no `expires_at` would
        #   never be swept, which is the caller's mistake to avoid, not
        #   something this method silently defaults for them
        def write(agent, project, scope, key, value, expires_at: nil)
          record = RedminefluxAgentosAgentMemory.find_or_initialize_by(
            agent_id: agent.id, project_id: project&.id, scope: scope.to_s, key: key.to_s
          )
          record.value_json = value.to_json
          record.expires_at = expires_at
          record.save!
          record
        end

        # Deletes `short_term` rows past `expires_at` — run as a scheduled
        # background job, never on every read, so read latency isn't
        # coupled to cleanup (§A.9).
        def sweep_expired
          RedminefluxAgentosAgentMemory
            .where(scope: 'short_term')
            .where('expires_at IS NOT NULL AND expires_at <= ?', Time.now)
            .delete_all
        end

        private

        def parse(value_json)
          return nil if value_json.nil?

          JSON.parse(value_json)
        rescue JSON::ParserError
          value_json
        end
      end
    end
  end
end
