# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # Common contract every agent implements (docs/AGENTS.md intro,
    # docs/PHASE6-AGENT-ARCHITECTURE.md). `AgentEngine::Runner` calls this
    # contract uniformly across every agent — no agent-specific branching
    # in the Runner (Liskov Substitution, docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
    # §A.3): the Runner owns the cross-cutting mechanical steps (memory
    # fetch/write, tool-call execution, lifecycle transition) identically
    # for every agent; each subclass here owns only what genuinely varies
    # per role — which prompt category to resolve and what variables to
    # build the request from — then calls the Provider itself and returns
    # the raw Standard Response (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md
    # §2.2) for the Runner to act on.
    #
    # Subclasses declare `.key` and `.prompt_category` (required);
    # `.scenario_key` is optional, defaulting to `prompt_category` itself
    # — the same convention `MockProvider` already uses (rao-017) for
    # every category with exactly one scenario.
    class BaseAgent
      class << self
        def key
          raise NotImplementedError, "#{name} must define .key"
        end

        def prompt_category
          raise NotImplementedError, "#{name} must define .prompt_category"
        end

        def scenario_key
          nil
        end

        def prompt_template_key
          "#{prompt_category}.default"
        end
      end

      def initialize(agent_run)
        @agent_run = agent_run
      end

      # @param memory [Array<Hash>] `{key:, value:}` rows already fetched
      #   by the Runner via `MemoryStore::Repository.fetch` — passed in,
      #   not fetched again here, so this class stays testable without a
      #   full Runner/DB round trip
      # @return [Hash] Standard Response Model, §2.2
      def call(memory: [])
        variables = build_variables(memory)
        prompt = RedminefluxAgentos::Prompts::TemplateResolver.resolve(
          self.class.prompt_template_key, agent: agent_record, variables: variables
        )

        provider = RedminefluxAgentos::Providers::Registry.active(project: @agent_run.project)
        provider.request(
          agent_key: self.class.key.to_s,
          prompt_category: self.class.prompt_category,
          scenario_key: self.class.scenario_key,
          prompt: prompt,
          variables: variables,
          conversation_id: @agent_run.conversation_id,
          agent_run_id: @agent_run.id,
          context: memory,
          tools_available: agent_record.tool_allowlist,
          idempotency_key: "agent_run-#{@agent_run.id}"
        )
      end

      private

      def agent_record
        @agent_record ||= @agent_run.agent
      end

      # Base variables come from `agent_runs.input_json` — "Snapshot of
      # what an agent run received" (docs/DATABASE-SCHEMA.md's own
      # description of that column) — populated by whichever caller
      # queues the run (Scheduler, a conversation turn), not derived here.
      def build_variables(memory)
        base = @agent_run.input_json.present? ? JSON.parse(@agent_run.input_json) : {}
        base.merge('memory' => memory)
      rescue JSON::ParserError
        { 'memory' => memory }
      end
    end
  end
end
