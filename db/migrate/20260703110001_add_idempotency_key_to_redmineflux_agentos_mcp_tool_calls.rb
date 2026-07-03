# frozen_string_literal: true

# Additive gap-fill discovered during rao-018 (Phase 13, MCP
# Implementation): docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §2.1 and
# docs/MCP-TOOLS.md's "Execution guarantees" both require idempotency-key
# tracking ("a retried agent run doesn't create duplicate issues"), and
# rao-018's own Objectives require implementing it — but no column to
# actually persist and look up an idempotency key was ever added to
# `redmineflux_agentos_mcp_tool_calls` in `docs/DATABASE-SCHEMA.md` or
# `rao-016`'s migrations. CLAUDE.md's "Backward compatibility — additive
# params/columns with defaults" rule applies: this is a new, nullable,
# purely additive column, not a change to any existing one. Nullable
# because read-only tool calls and any caller that doesn't supply a key
# don't need one; a unique index still works correctly with NULLs on
# MySQL, PostgreSQL, and SQLite alike (NULLs never collide).
class AddIdempotencyKeyToRedminefluxAgentosMcpToolCalls < ActiveRecord::Migration[6.1]
  def change
    add_column :redmineflux_agentos_mcp_tool_calls, :idempotency_key, :string
    add_index :redmineflux_agentos_mcp_tool_calls, :idempotency_key, unique: true,
                                                                      name: 'idx_agentos_mcp_calls_idempotency'
  end
end
