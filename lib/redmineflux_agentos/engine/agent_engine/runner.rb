# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module AgentEngine
      # AgentEngine::Runner — executes one agent_run end to end: loads the
      # agent + memory, resolves the prompt, calls the active Provider,
      # executes any requested tool calls via Mcp::Executor, writes memory
      # updates, and transitions the run via Lifecycle
      # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.5,
      # docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §5). Enforces the
      # Concurrency Guard atomically before queued -> running
      # (rao-007/rao-009 carried-forward requirement). Phase 14 (rao-019)
      # implements the body.
      module Runner
        def self.execute(agent_run)
          raise NotImplementedError, 'Agent run execution is implemented in Phase 14 (rao-019)'
        end
      end
    end
  end
end
