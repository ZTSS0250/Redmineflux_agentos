# frozen_string_literal: true

module RedminefluxAgentos
  module Mcp
    # Mcp::Executor — the single write path to Redmine for every AgentOS
    # action (docs/PHASE7-MCP-ARCHITECTURE.md §1). Owns the Permission
    # Model's two independent layers, the confirmation gate, idempotency-key
    # deduplication, secrets redaction, and audit logging.
    #
    # Two interpretive decisions made here, beyond what
    # docs/PHASE7-MCP-ARCHITECTURE.md states outright (both logged as a
    # transparent Gate 1 revision in rao-018 — see that ticket):
    #
    # 1. Layer 1 ("Redmine authorize?") is delegated to each tool's own
    #    `authorize:` proc (registered alongside `params_schema`), not
    #    resolved generically here — only a tool's own handler knows how
    #    to find its target Project/Issue from `params`. This keeps
    #    Executor itself tool-agnostic (Open/Closed, Phase 2 §A.3): adding
    #    a tool is a new registry entry, never a change to this file.
    # 2. `agent:` is an additional, optional keyword `Mcp::Executor.call`
    #    accepts beyond the originally-stubbed signature — Layer 2 (the
    #    calling agent's tool_allowlist) cannot be checked without knowing
    #    which agent is calling, and a human-initiated call (a Pending
    #    Approvals confirmation, an SRS approval) legitimately has none;
    #    Layer 2 is skipped (trivially allowed) when `agent` is nil.
    module Executor
      class << self
        # @param tool_name [Symbol, String]
        # @param params [Hash]
        # @param actor [User] required, never defaulted — Phase 2 §B.8. For
        #   agent-initiated calls this is the AgentOS System user
        #   (rao-015, docs/PHASE7-MCP-ARCHITECTURE.md §3); for
        #   human-initiated calls it's the real logged-in user.
        # @param idempotency_key [String, nil] per-call, already
        #   index-suffixed by the caller for a multi-call turn
        #   (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §2.1/§2.5)
        # @param agent [RedminefluxAgentosAgent, nil] the calling agent,
        #   for Layer 2 — nil for a human-initiated call
        # @param agent_run [RedminefluxAgentosAgentRun, nil] rao-021
        #   addition (backward-compatible, additive, defaults to nil like
        #   `agent:` above) — the run that triggered this call, when one
        #   exists. Threaded through to `mcp_tool_calls.agent_run_id`,
        #   which nothing populated before rao-021 (every row had a null
        #   FK regardless of caller) — closing that gap is what lets
        #   `NotificationCenter.approval_needed` resolve a project (and
        #   so a recipient list) from a `pending_confirmation` row at
        #   all, per WORKFLOW.md §23.
        # @return [Hash] `{status:, result:, error: nil}` — only ever
        #   returned on success; failure paths raise (see class comment)
        def call(tool_name:, params:, actor:, idempotency_key: nil, agent: nil, agent_run: nil)
          tool_name = tool_name.to_sym
          declaration = ToolRegistry.lookup(tool_name)
          raise ArgumentError, "Unknown MCP tool: #{tool_name}" unless declaration

          existing = find_existing(idempotency_key)
          return replay(existing) if existing

          begin
            validate_params!(tool_name, declaration[:params_schema], params)
            authorize_layer_1!(declaration, actor, params)
            authorize_layer_2!(agent, tool_name)
          rescue RedminefluxAgentos::McpToolError => e
            record_failure!(tool_name, declaration, params, actor, idempotency_key, e, agent_run)
            raise
          end

          if declaration[:requires_confirmation]
            record = create_call_row(tool_name, declaration, params, actor, idempotency_key,
                                      status: 'pending_confirmation', agent_run: agent_run)
            RedminefluxAgentos::Engine::EventBus.publish('mcp_tool_call.pending_confirmation', record: record)
            return { status: :pending_confirmation, result: nil, error: nil }
          end

          execute_and_record(tool_name, declaration, params, actor, idempotency_key, agent, agent_run)
        end

        # Executes a previously `pending_confirmation` call. The original
        # actor's permission was already established when the call was
        # first queued — re-checking it here would just re-derive the same
        # answer, so this step only re-runs the handler and finalizes the
        # row. Whether `confirmed_by` is itself allowed to approve is a
        # controller-level `authorize` concern (the Pending Approvals
        # queue, Phase 15) — this is the model/service-layer primitive it
        # calls once that check has already passed.
        def confirm(mcp_tool_call_id, confirmed_by:)
          # Deliberately NOT inside the begin/rescue below: a bad id
          # (RecordNotFound) or an already-resolved call (ArgumentError)
          # is the caller's mistake, not a tool-execution failure — it
          # must propagate as-is, not get reclassified/masked by the
          # handler-execution rescue further down.
          record = RedminefluxAgentosMcpToolCall.find(mcp_tool_call_id)
          raise ArgumentError, "##{mcp_tool_call_id} is not pending confirmation" unless record.status == 'pending_confirmation'

          declaration = ToolRegistry.lookup(record.tool_name.to_sym)
          raise ArgumentError, "Unknown MCP tool: #{record.tool_name}" unless declaration

          params = record.params_json.present? ? JSON.parse(record.params_json) : {}
          actor = record.user || confirmed_by

          begin
            started_at = Time.now
            result = run_handler(declaration, params, actor)
            duration_ms = ((Time.now - started_at) * 1000).round
          rescue StandardError => e
            classified = classify(e)
            record.update!(status: 'failed', result_json: error_payload(classified).to_json,
                            confirmed_by_id: confirmed_by.id)
            raise classified
          end

          result_json = result[:result].to_json
          record.update!(status: 'executed', result_json: result_json, confirmed_by_id: confirmed_by.id,
                          duration_ms: duration_ms)
          record_audit!(declaration, actor, nil, result)
          # Same string-keyed normalization as execute_and_record — see
          # its comment.
          { status: :executed, result: JSON.parse(result_json), error: nil }
        end

        # A human rejects a pending confirmation — a normal terminal
        # outcome, not an error (docs/PHASE7-MCP-ARCHITECTURE.md §5).
        def reject(mcp_tool_call_id, confirmed_by:)
          record = RedminefluxAgentosMcpToolCall.find(mcp_tool_call_id)
          raise ArgumentError, "##{mcp_tool_call_id} is not pending confirmation" unless record.status == 'pending_confirmation'

          record.update!(status: 'rejected', confirmed_by_id: confirmed_by.id)
          { status: :rejected, result: nil, error: nil }
        end

        private

        def find_existing(idempotency_key)
          return nil if idempotency_key.blank?

          RedminefluxAgentosMcpToolCall.find_by(idempotency_key: idempotency_key)
        end

        def replay(record)
          case record.status
          when 'executed'
            { status: :executed, result: record.result_json.present? ? JSON.parse(record.result_json) : nil, error: nil }
          when 'pending_confirmation'
            { status: :pending_confirmation, result: nil, error: nil }
          when 'rejected'
            { status: :rejected, result: nil, error: nil }
          else # 'failed'
            { status: :failed, result: nil, error: record.result_json.present? ? JSON.parse(record.result_json) : nil }
          end
        end

        def validate_params!(tool_name, schema, params)
          params ||= {}
          missing = schema.select { |key, spec| spec[:required] && params[key].nil? && params[key.to_s].nil? }.keys
          unless missing.empty?
            raise RedminefluxAgentos::McpToolError::InvalidParamsError,
                  "#{tool_name}: missing required param(s): #{missing.join(', ')}"
          end

          type_errors = schema.filter_map do |key, spec|
            next unless spec[:type]

            value = params.key?(key) ? params[key] : params[key.to_s]
            "#{key} must be a #{spec[:type]}" if !value.nil? && !value.is_a?(spec[:type])
          end
          return if type_errors.empty?

          raise RedminefluxAgentos::McpToolError::InvalidParamsError, "#{tool_name}: #{type_errors.join(', ')}"
        end

        def authorize_layer_1!(declaration, actor, params)
          return unless declaration[:authorize]
          return if declaration[:authorize].call(actor, params)

          raise RedminefluxAgentos::McpToolError::PermissionDeniedError,
                "#{actor.try(:login) || actor}: not permitted (Redmine authorization)"
        end

        def authorize_layer_2!(agent, tool_name)
          return unless agent # human-initiated call — Layer 2 doesn't apply

          return if ToolRegistry.tools_for(agent).include?(tool_name)

          raise RedminefluxAgentos::McpToolError::PermissionDeniedError,
                "#{tool_name} is not in #{agent.key}'s tool_allowlist"
        end

        def execute_and_record(tool_name, declaration, params, actor, idempotency_key, agent, agent_run)
          started_at = Time.now
          result = run_handler(declaration, params, actor)
          duration_ms = ((Time.now - started_at) * 1000).round
          result_json = result[:result].to_json

          create_call_row(tool_name, declaration, params, actor, idempotency_key,
                           status: 'executed', result_json: result_json, duration_ms: duration_ms, agent_run: agent_run)
          record_audit!(declaration, actor, agent, result)
          # Round-tripped through JSON (string-keyed) rather than returning
          # `result[:result]` (whatever key types the handler happened to
          # use) — a replayed idempotent call (`replay`, above) can only
          # ever reconstruct a result from the persisted `result_json`, so
          # a fresh execution and a replay of the exact same call must
          # return identically-shaped data, not one symbol-keyed and the
          # other string-keyed depending on which path served it.
          { status: :executed, result: JSON.parse(result_json), error: nil }
        rescue StandardError => e
          classified = classify(e)
          record_failure!(tool_name, declaration, params, actor, idempotency_key, classified, agent_run)
          raise classified
        end

        def run_handler(declaration, params, actor)
          declaration[:handler].call(params, actor)
        end

        def classify(error)
          return error if error.is_a?(RedminefluxAgentos::McpToolError)
          return RedminefluxAgentos::McpToolError::RedmineValidationError.new(error.message) if error.is_a?(ActiveRecord::RecordInvalid)
          if error.is_a?(ActiveRecord::RecordNotFound)
            return RedminefluxAgentos::McpToolError::RedmineValidationError.new(error.message)
          end

          RedminefluxAgentos::McpToolError::UnexpectedError.new(error.message, original: error)
        end

        def record_failure!(tool_name, declaration, params, actor, idempotency_key, error, agent_run = nil)
          create_call_row(tool_name, declaration, params, actor, idempotency_key, status: 'failed',
                                                                                   result_json: error_payload(error).to_json,
                                                                                   agent_run: agent_run)
        end

        def error_payload(error)
          {
            error_code: error.class.name.demodulize.underscore,
            message: error.message,
            retryable: error.is_a?(RedminefluxAgentos::McpToolError::UnexpectedError)
          }
        end

        def create_call_row(tool_name, declaration, params, actor, idempotency_key, status:, result_json: nil,
                             duration_ms: nil, agent_run: nil)
          RedminefluxAgentosMcpToolCall.create!(
            tool_name: tool_name.to_s,
            user_id: actor&.id,
            agent_run_id: agent_run&.id,
            params_json: redact(params, declaration[:params_schema]).to_json,
            result_json: result_json,
            status: status,
            requires_confirmation: declaration[:requires_confirmation] || false,
            idempotency_key: idempotency_key.presence,
            duration_ms: duration_ms
          )
        end

        # Allow-list based redaction (Gate 2 finding #2, rao-018) — only
        # params a tool's schema explicitly marks `sensitive: true` are
        # redacted; every other param is stored as-is. New params are
        # unloggable-as-plaintext only if a tool author opts in, but
        # nothing is redacted by default that wasn't asked for — the
        # allow-list is "which keys may be logged in the clear", not "which
        # keys are secret", per docs/PHASE4-DATABASE-DESIGN.md §7's rule.
        def redact(params, schema)
          return {} if params.nil?

          params.each_with_object({}) do |(key, value), out|
            spec = schema[key.to_sym] || schema[key.to_s.to_sym]
            out[key] = spec && spec[:sensitive] ? '[REDACTED]' : value
          end
        end

        # Only non-read-only tools get an audit_logs row — read-only tools
        # (search_*/read_*) are exempt per docs/MCP-TOOLS.md's Execution
        # guarantees (too high volume to be useful as an audit trail).
        def record_audit!(declaration, actor, agent, handler_result)
          return if declaration[:read_only]
          return unless handler_result[:action]

          RedminefluxAgentosAuditLog.create!(
            user_id: actor&.id,
            agent_id: agent&.id,
            action: handler_result[:action],
            target_type: handler_result[:target_type],
            target_id: handler_result[:target_id],
            before_json: handler_result[:before]&.to_json,
            after_json: handler_result[:after]&.to_json
          )
        end
      end
    end
  end
end
