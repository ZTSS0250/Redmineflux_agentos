# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # Common contract every agent implements (docs/AGENTS.md intro,
    # docs/PHASE6-AGENT-ARCHITECTURE.md). AgentEngine::Runner calls this
    # contract uniformly across every agent — no agent-specific branching
    # in the Runner (Liskov Substitution, docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
    # §A.3). Subclasses declare `.key`; actual execution logic is Phase 14
    # (Multi-Agent Orchestration, rao-019) — this is a skeleton only.
    class BaseAgent
      class << self
        def key
          raise NotImplementedError, "#{name} must define .key"
        end
      end

      def initialize(agent_run)
        @agent_run = agent_run
      end

      # Executes this agent's turn against the active Provider and returns
      # a Standard Response (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §2.2).
      def call
        raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 14 (rao-019)"
      end
    end
  end
end
