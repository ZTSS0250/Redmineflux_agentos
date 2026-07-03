# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module AgentEngine
      # AgentEngine::Runner — executes one agent_run end to end: attempts
      # the concurrency-guarded `queued -> running` transition, loads the
      # agent + memory, calls the agent (which resolves its own prompt and
      # calls the active Provider), executes any requested tool calls via
      # Mcp::Executor, writes memory updates, records token usage, and
      # transitions the run to its outcome via Lifecycle
      # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.5,
      # docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §5).
      #
      # Every agent-initiated MCP call uses the AgentOS System user as
      # `actor:` (docs/PHASE7-MCP-ARCHITECTURE.md §3) — never `User.current`,
      # which has no meaning inside a background job — and this Runner
      # ensures that user is a project Member before dispatching any call,
      # so Layer 1 (Redmine's own authorization) has a real Role/Membership
      # to check against, not just a bare user record (rao-015).
      module Runner
        class << self
          # @param agent_run [RedminefluxAgentosAgentRun] must currently be
          #   `queued`
          # @return [Symbol] `:completed`, `:failed`, or `:not_started`
          #   (still `queued` — paused or at the concurrency cap; normal
          #   backpressure, not an error)
          def execute(agent_run)
            return :not_started unless Lifecycle.transition(agent_run, :start)

            begin
              response = run_agent(agent_run)
              apply_response(agent_run, response)
              Lifecycle.transition(agent_run, :complete)
              :completed
            rescue StandardError => e
              Lifecycle.record_failure!(agent_run, error_message: e.message)
              :failed
            end
          end

          private

          def run_agent(agent_run)
            agent_record = agent_run.agent
            agent_class = Registry.for(agent_record.key.to_sym)
            memory = RedminefluxAgentos::MemoryStore::Repository.fetch(agent_record, agent_run.project)

            agent_class.new(agent_run).call(memory: memory)
          end

          def apply_response(agent_run, response)
            agent_record = agent_run.agent

            execute_tool_calls(agent_run, agent_record, response[:tool_calls])
            write_memory_updates(agent_record, agent_run.project, response[:memory_updates])
            record_token_usage(agent_run, response[:usage])
          end

          def execute_tool_calls(agent_run, agent_record, tool_calls)
            return if tool_calls.blank?

            RedminefluxAgentos::SystemUserProvisioner.ensure_membership!(agent_run.project) if agent_run.project

            Array(tool_calls).each do |call|
              RedminefluxAgentos::Mcp::Executor.call(
                tool_name: call[:tool_name] || call['tool_name'],
                params: call[:params] || call['params'] || {},
                actor: RedminefluxAgentos::SystemUserProvisioner.user,
                idempotency_key: call[:idempotency_key] || call['idempotency_key'],
                agent: agent_record,
                agent_run: agent_run
              )
            end
          end

          def write_memory_updates(agent_record, project, updates)
            Array(updates).each do |update|
              scope = update[:scope] || update['scope']
              key = update[:key] || update['key']
              value = update[:value] || update['value']
              next if key.blank?

              RedminefluxAgentos::MemoryStore::Repository.write(agent_record, project, scope, key, value)
            end
          end

          def record_token_usage(agent_run, usage)
            return if usage.blank?

            RedminefluxAgentosTokenUsage.create!(
              agent_run_id: agent_run.id,
              project_id: agent_run.project_id,
              provider: usage[:provider] || usage['provider'] || 'mock',
              model: usage[:model] || usage['model'] || 'n/a',
              prompt_tokens: usage[:prompt_tokens] || usage['prompt_tokens'] || 0,
              completion_tokens: usage[:completion_tokens] || usage['completion_tokens'] || 0,
              total_tokens: usage[:total_tokens] || usage['total_tokens'] || 0
            )
          end
        end
      end
    end
  end
end
