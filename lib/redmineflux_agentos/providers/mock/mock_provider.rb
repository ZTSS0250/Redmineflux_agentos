# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    module Mock
      # The Mock AI Provider (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §1).
      # Deterministic, fixture-based, zero outbound network calls — this
      # invariant is verified by a dedicated test asserting no network call
      # is ever attempted (rao-017 Gate 2 finding #1). Orchestrates
      # Selector -> Loader -> Renderer -> (generation rule, if any) ->
      # Standard Response assembly (§1.2).
      class MockProvider
        include RedminefluxAgentos::Providers::ProviderInterface

        # The 11 categories in §6.1 — a provider is not required to
        # support every category (§2.4), but the Mock Provider supports
        # all of them since every one has at least a fallback fixture.
        SUPPORTED_CATEGORIES = %w[
          requirement_analysis clarification_questions srs_generation
          project_planning release_planning sprint_planning
          ticket_generation dependency_analysis risk_analysis
          documentation reporting
        ].freeze

        MAX_CONTEXT_TOKENS = 1_000_000
        DEFAULT_LATENCY_MS = 250

        def self.key
          :mock
        end

        # @param request [Hash] Standard Request Model, §2.1 — string or
        #   symbol keys accepted
        # @return [Hash] Standard Response Model, §2.2 (symbol keys)
        def request(request)
          request = request.transform_keys(&:to_sym)
          variables = (request[:variables] || {}).transform_keys(&:to_s)

          fixture = FixtureSelector.resolve(
            agent_key: request[:agent_key],
            prompt_category: request[:prompt_category],
            # The Standard Request Model (§2.1) has no dedicated field for
            # "which scenario within this category" — most categories map
            # 1:1 onto one scenario of the same name (§7); callers with
            # more than one scenario per category (e.g. Project Planning's
            # create_project / project_plan / agent_assignment) pass
            # `scenario_key` explicitly.
            scenario_key: request[:scenario_key] || request[:prompt_category],
            round_number: variables['round_number']
          )

          rendered = FixtureRenderer.render(fixture, variables)
          rendered = apply_generation_rule(rendered, variables)

          build_response(rendered, request)
        end

        # @return [Hash] Capability Model, §2.4
        def capabilities
          {
            supports_tool_calling: true,
            supports_streaming: false,
            max_context_tokens: MAX_CONTEXT_TOKENS,
            supported_categories: SUPPORTED_CATEGORIES
          }
        end

        private

        # "Ticket Creation" (§7.2) is the one scenario whose content is a
        # deterministic ALGORITHM, not hand-authored fixture content — the
        # fixture only declares `generation_rule: ticket_generation` plus
        # the static usage/latency/finish_reason fields; the actual
        # tool_calls are built here from the request's `epic` variable.
        def apply_generation_rule(rendered, variables)
          return rendered unless rendered['generation_rule'] == 'ticket_generation'

          epic = variables['epic'] || {}
          stories = TicketGenerationRule.generate(epic)

          rendered = rendered.dup
          rendered['tool_calls'] = stories.flat_map { |story| story_to_tool_calls(story) }
          rendered
        end

        def story_to_tool_calls(story)
          story = story.dup
          tasks = story.delete('tasks') || []
          ([story] + tasks).map do |item|
            { 'tool_name' => 'redmineflux_agentos_create_issue', 'params' => item }
          end
        end

        def build_response(rendered, request)
          prompt_tokens = rendered.dig('usage', 'prompt_tokens').to_i
          completion_tokens = rendered.dig('usage', 'completion_tokens').to_i

          {
            content: rendered['content'],
            tool_calls: build_tool_calls(rendered['tool_calls'], request[:idempotency_key]),
            memory_updates: rendered['memory_updates'],
            usage: {
              prompt_tokens: prompt_tokens,
              completion_tokens: completion_tokens,
              total_tokens: prompt_tokens + completion_tokens
            },
            # A fixed value (§2.2) — default 250ms, fixture-overridable,
            # never randomized, so determinism (§1) is never broken by an
            # unrelated timing field.
            latency_ms: rendered['latency_ms'] || DEFAULT_LATENCY_MS,
            finish_reason: (rendered['finish_reason'] || 'content').to_sym,
            provider: 'mock',
            model: 'n/a',
            raw: rendered
          }
        end

        # Idempotency-key suffixing (§2.1/§2.5): when a turn produces
        # multiple tool_calls, each call's effective idempotency key is
        # `{idempotency_key}-{n}`, n being its zero-based index — never the
        # same raw key reused across calls, or Mcp::Executor's idempotency
        # check would see N calls as N retries of the same call and
        # silently drop all but the first.
        def build_tool_calls(tool_calls, base_idempotency_key)
          calls = Array(tool_calls)
          return nil if calls.empty?

          calls.each_with_index.map do |call, index|
            {
              tool_name: call['tool_name'] || call[:tool_name],
              params: call['params'] || call[:params] || {},
              idempotency_key: "#{base_idempotency_key}-#{index}"
            }
          end
        end
      end
    end
  end
end
