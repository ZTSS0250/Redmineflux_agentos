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
        end
      end
    end
  end
end
